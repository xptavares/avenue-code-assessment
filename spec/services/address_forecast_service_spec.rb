require "rails_helper"

RSpec.describe AddressForecastService do
  subject(:service) { described_class.new(address, geocoder:, forecaster:, cache:) }

  let(:geocoder) { class_double(GeocodingService) }
  let(:forecaster) { class_double(ForecastService) }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:address) { Geocoding::Address.new(street: "123 Rua das Acácias", city: "Vila Esperança", postalcode: "12345-678") }
  let(:location) { Geocoding::Result.new(latitude: -10.5432, longitude: -40.2109, postal_code: "12345-678") }
  let(:forecast) do
    Forecast::Result.new(current_temperature: 21.4, days: [ Forecast::Day.new(date: Date.new(2026, 1, 15), high: 27.0, low: 18.2, precipitation_probability: 25, precipitation_sum: 1.2, hours: []) ])
  end

  before do
    freeze_time
    allow(geocoder).to receive(:call).and_return(location)
    allow(forecaster).to receive(:call).with(latitude: -10.5432, longitude: -40.2109).and_return(forecast)
  end

  describe "#call" do
    context "when the postal code is not cached" do
      it "returns a fresh forecast fetched now" do
        expect(service.call).to eq(described_class::Result.new(forecast:, cached: false, fetched_at: Time.current))
      end

      it "stores the forecast and fetch time under the normalized postal code" do
        service.call

        expect(cache.read("forecast/12345678")).to eq(forecast:, fetched_at: Time.current)
      end
    end

    context "when the postal code is cached" do
      before { cache.write("forecast/12345678", { forecast:, fetched_at: 10.minutes.ago }) }

      it "returns the cached forecast with its original fetch time" do
        expect(service.call).to eq(described_class::Result.new(forecast:, cached: true, fetched_at: 10.minutes.ago))
      end

      it "does not call the external services" do
        service.call

        expect([ geocoder, forecaster ]).to all(have_received(:call).exactly(0).times)
      end
    end

    context "when the address has no postal code" do
      let(:address) { Geocoding::Address.new(street: "123 Rua das Acácias", city: "Vila Esperança") }

      it "caches by the postal code found by geocoding" do
        service.call

        expect(cache.read("forecast/12345678")).to include(forecast:)
      end

      it "geocodes the address only once" do
        service.call

        expect(geocoder).to have_received(:call).once
      end
    end

    context "when no postal code is available" do
      let(:address) { Geocoding::Address.new(street: "123 Rua das Acácias", city: "Vila Esperança") }
      let(:location) { Geocoding::Result.new(latitude: -10.5432, longitude: -40.2109, postal_code: nil) }

      it "returns a fresh forecast without caching" do
        expect(service.call).to eq(described_class::Result.new(forecast:, cached: false, fetched_at: Time.current))
      end
    end

    context "when the cache entry has expired" do
      before { cache.write("forecast/12345678", { forecast:, fetched_at: Time.current }, expires_in: described_class::CACHE_TTL) }

      it "fetches a fresh forecast" do
        travel(described_class::CACHE_TTL + 1.second) do
          expect(service.call.cached).to be(false)
        end
      end
    end
  end

  describe "Result#expires_at" do
    it "is the fetch time plus the cache TTL" do
      result = described_class::Result.new(forecast:, cached: true, fetched_at: Time.current)

      expect(result.expires_at).to eq(30.minutes.from_now)
    end
  end
end
