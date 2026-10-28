require "rails_helper"

RSpec.describe Forecast::OpenMeteoProvider do
  subject(:provider) { described_class.new }

  let(:forecast_url) { "https://api.open-meteo.com/v1/forecast" }
  let(:response_body) do
    {
      timezone: "America/Sao_Paulo",
      utc_offset_seconds: -10_800,
      current: { time: "2026-01-15T14:00", temperature_2m: 21.4 },
      daily: {
        time: [ "2026-01-15", "2026-01-16" ],
        temperature_2m_max: [ 27.0, 25.3 ],
        temperature_2m_min: [ 18.2, 17.9 ],
        precipitation_probability_max: [ 25, 80 ],
        precipitation_sum: [ 1.2, 14.5 ]
      },
      hourly: {
        time: [ "2026-01-15T15:00", "2026-01-15T16:00", "2026-01-16T15:00" ],
        temperature_2m: [ 26.1, 25.4, 22.0 ],
        precipitation_probability: [ 20, 25, 80 ],
        precipitation: [ 0.4, 0.8, 3.1 ]
      }
    }
  end

  def stub_forecast(status: 200, body: response_body)
    stub_request(:get, forecast_url)
      .with(query: hash_including(latitude: "-10.5432", longitude: "-40.2109"))
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def forecast
    provider.forecast(latitude: -10.5432, longitude: -40.2109)
  end

  describe "#forecast" do
    context "when the request succeeds" do
      before { stub_forecast }

      it "returns the current temperature" do
        expect(forecast.current_temperature).to eq(21.4)
      end

      it "returns the daily summary" do
        expect(forecast.days.first).to have_attributes(
          date: Date.new(2026, 1, 15), high: 27.0, low: 18.2, precipitation_probability: 25, precipitation_sum: 1.2
        )
      end

      it "groups the hours under their day" do
        expect(forecast.days.map { it.hours.size }).to eq([ 2, 1 ])
      end

      it "parses the hours in the location's time zone" do
        expect(forecast.days.first.hours.first).to have_attributes(
          time: Time.iso8601("2026-01-15T15:00:00-03:00"), temperature: 26.1, precipitation_probability: 20, precipitation: 0.4
        )
      end
    end

    context "when a day has no hourly data" do
      before { stub_forecast(body: response_body.merge(hourly: { time: [], temperature_2m: [], precipitation_probability: [], precipitation: [] })) }

      it "returns the day with no hours" do
        expect(forecast.days.map(&:hours)).to all(be_empty)
      end
    end

    context "when the response is missing data" do
      before { stub_forecast(body: response_body.except(:hourly)) }

      it "raises a Forecast::Error" do
        expect { forecast }.to raise_error(Forecast::Error, "Unexpected response from Open-Meteo")
      end
    end

    context "when Open-Meteo returns an error status" do
      before { stub_forecast(status: 400, body: { error: true, reason: "Latitude must be in range of -90 to 90°" }) }

      it "raises a Forecast::Error" do
        expect { forecast }.to raise_error(Forecast::Error, /Open-Meteo request failed/)
      end
    end

    context "when the request times out" do
      before { stub_request(:get, forecast_url).with(query: hash_including({})).to_timeout }

      it "raises a Forecast::Error" do
        expect { forecast }.to raise_error(Forecast::Error, /Open-Meteo request failed/)
      end
    end
  end
end
