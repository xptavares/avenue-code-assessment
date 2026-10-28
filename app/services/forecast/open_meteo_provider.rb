module Forecast
  class OpenMeteoProvider
    BASE_URL = "https://api.open-meteo.com".freeze
    FORECAST_DAYS = 7
    DAILY_FIELDS = %w[temperature_2m_max temperature_2m_min precipitation_probability_max precipitation_sum].freeze
    HOURLY_FIELDS = %w[temperature_2m precipitation_probability precipitation].freeze

    def forecast(latitude:, longitude:)
      response = connection.get("/v1/forecast", {
        latitude:,
        longitude:,
        current: "temperature_2m",
        daily: DAILY_FIELDS.join(","),
        hourly: HOURLY_FIELDS.join(","),
        timezone: "auto",
        forecast_days: FORECAST_DAYS
      })

      build_result(response.body)
    rescue Faraday::Error => e
      raise Error, "Open-Meteo request failed: #{e.message}"
    rescue KeyError, TypeError, NoMethodError, ArgumentError
      raise Error, "Unexpected response from Open-Meteo"
    end

    private

    def build_result(body)
      zone = ActiveSupport::TimeZone[body.fetch("timezone")] || ActiveSupport::TimeZone[body.fetch("utc_offset_seconds")]
      hours_by_date = build_hours(body.fetch("hourly"), zone).group_by { it.time.to_date }

      days = rows(body.fetch("daily"), DAILY_FIELDS).map do |date, high, low, probability, sum|
        date = Date.iso8601(date)
        Day.new(date:, high:, low:, precipitation_probability: probability, precipitation_sum: sum, hours: hours_by_date.fetch(date, []))
      end

      Result.new(current_temperature: body.fetch("current").fetch("temperature_2m"), days:)
    end

    def build_hours(hourly, zone)
      rows(hourly, HOURLY_FIELDS).map do |time, temperature, probability, precipitation|
        Hour.new(time: zone.iso8601("#{time}:00"), temperature:, precipitation_probability: probability, precipitation:)
      end
    end

    # Open-Meteo returns one array per field; this turns them into one row per timestamp
    def rows(section, fields)
      section.fetch("time").zip(*fields.map { section.fetch(it) })
    end

    def connection
      @connection ||= Faraday.new(BASE_URL, request: { timeout: 5, open_timeout: 2 }) do |f|
        f.response :raise_error
        f.response :json
      end
    end
  end
end
