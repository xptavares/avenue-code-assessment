require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  let(:address_params) { { street: "123 Rua das Acácias", city: "Vila Esperança", postalcode: "12345-678" } }
  let(:address) { Geocoding::Address.new(**address_params) }
  let(:forecast) do
    Forecast::Result.new(
      current_temperature: 21.4,
      days: [
        Forecast::Day.new(
          date: Date.new(2026, 1, 15), high: 27.0, low: 18.2, precipitation_probability: 25, precipitation_sum: 1.2,
          hours: [ Forecast::Hour.new(time: Time.zone.parse("2026-01-15 15:00"), temperature: 26.1, precipitation_probability: 25, precipitation: 0.8) ]
        ),
        Forecast::Day.new(date: Date.new(2026, 1, 16), high: 25.3, low: 17.9, precipitation_probability: 80, precipitation_sum: 14.5, hours: [])
      ]
    )
  end

  describe "GET /forecast" do
    context "when the lookup succeeds" do
      before do
        allow(AddressForecastService).to receive(:call).with(address)
          .and_return(AddressForecastService::Result.new(forecast:, cached: false))
      end

      it "shows today's forecast" do
        get forecast_path, params: { address: address_params }

        expect(response.body).to include("Now: 21°C", "High: 27°C / Low: 18°C", "Chance of rain: 25% (1.2 mm)")
      end

      it "shows the hourly forecast" do
        get forecast_path, params: { address: address_params }

        expect(response.body).to include("<td>15:00</td>", "<td>26°C</td>")
      end

      it "shows the next days" do
        get forecast_path, params: { address: address_params }

        expect(response.body).to include("Fri, Jan 16", "<td>80%</td>")
      end

      it "does not show the cache notice for a fresh result" do
        get forecast_path, params: { address: address_params }

        expect(response.body).not_to include("Cached result")
      end
    end

    context "when the result comes from the cache" do
      before do
        allow(AddressForecastService).to receive(:call).and_return(AddressForecastService::Result.new(forecast:, cached: true))
      end

      it "shows the cache notice" do
        get forecast_path, params: { address: address_params }

        expect(response.body).to include("Cached result")
      end
    end

    context "when street or city is missing" do
      it "redirects back to the form" do
        get forecast_path, params: { address: { street: "123 Rua das Acácias" } }

        expect(response).to redirect_to(root_path(address: { street: "123 Rua das Acácias" }))
      end

      it "shows an error message" do
        get forecast_path, params: { address: { street: "123 Rua das Acácias" } }

        expect(flash[:alert]).to eq("Street and city are required.")
      end
    end

    context "when the address is not found" do
      before { allow(AddressForecastService).to receive(:call).and_raise(Geocoding::NotFoundError) }

      it "redirects back to the form with an error message" do
        get forecast_path, params: { address: address_params }

        expect(flash[:alert]).to eq("We couldn't find that address. Check it and try again.")
      end
    end

    context "when an external service fails" do
      before { allow(AddressForecastService).to receive(:call).and_raise(Forecast::Error) }

      it "redirects back to the form with an error message" do
        get forecast_path, params: { address: address_params }

        expect(flash[:alert]).to eq("The forecast is unavailable right now. Please try again later.")
      end
    end
  end
end
