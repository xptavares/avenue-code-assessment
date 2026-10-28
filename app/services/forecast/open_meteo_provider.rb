module Forecast
  class OpenMeteoProvider
    BASE_URL = "https://api.open-meteo.com".freeze
    FORECAST_DAYS = 7

    def forecast(latitude:, longitude:)
      response = connection.get("/v1/forecast", {
        latitude:,
        longitude:,
        current: "temperature_2m",
        daily: "temperature_2m_max,temperature_2m_min",
        timezone: "auto",
        forecast_days: FORECAST_DAYS
      })

      build_result(response.body)
    rescue Faraday::Error => e
      raise Error, "Open-Meteo request failed: #{e.message}"
    rescue KeyError, TypeError, NoMethodError
      raise Error, "Unexpected response from Open-Meteo"
    end

    private

    def build_result(body)
      daily = body.fetch("daily")
      days = daily.fetch("time").zip(daily.fetch("temperature_2m_max"), daily.fetch("temperature_2m_min")).map do |date, high, low|
        Day.new(date: Date.parse(date), high:, low:)
      end

      Result.new(current_temperature: body.fetch("current").fetch("temperature_2m"), days:)
    end

    def connection
      @connection ||= Faraday.new(BASE_URL, request: { timeout: 5, open_timeout: 2 }) do |f|
        f.response :raise_error
        f.response :json
      end
    end
  end
end
