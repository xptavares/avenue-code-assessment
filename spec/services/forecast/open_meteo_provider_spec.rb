require "rails_helper"

RSpec.describe Forecast::OpenMeteoProvider do
  subject(:provider) { described_class.new }

  let(:forecast_url) { "https://api.open-meteo.com/v1/forecast" }
  let(:response_body) do
    {
      current: { time: "2026-01-15T14:00", temperature_2m: 21.4 },
      daily: {
        time: [ "2026-01-15", "2026-01-16" ],
        temperature_2m_max: [ 27.0, 25.3 ],
        temperature_2m_min: [ 18.2, 17.9 ]
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

      it "returns one entry per day" do
        expect(forecast.days).to eq([
          Forecast::Day.new(date: Date.new(2026, 1, 15), high: 27.0, low: 18.2),
          Forecast::Day.new(date: Date.new(2026, 1, 16), high: 25.3, low: 17.9)
        ])
      end
    end

    context "when the response is missing data" do
      before { stub_forecast(body: { current: { temperature_2m: 21.4 } }) }

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
