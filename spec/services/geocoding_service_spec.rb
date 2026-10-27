require "rails_helper"

RSpec.describe GeocodingService do
  subject(:service) { described_class.new(address, provider: provider) }

  let(:provider) { instance_double(Geocoding::NominatimProvider) }
  let(:result) { Geocoding::Result.new(latitude: -10.54, longitude: -40.21, postal_code: "12345-678") }
  let(:address) { Geocoding::Address.new(street: "123 Rua das Acácias", city: "Vila Esperança") }

  describe "#call" do
    context "with a valid address" do
      before { allow(provider).to receive(:geocode).with(address).and_return(result) }

      it "returns the provider result" do
        expect(service.call).to eq(result)
      end
    end

    context "without a street" do
      let(:address) { Geocoding::Address.new(street: "", city: "Vila Esperança") }

      it "raises an ArgumentError" do
        expect { service.call }.to raise_error(ArgumentError, "street and city are required")
      end
    end

    context "without a city" do
      let(:address) { Geocoding::Address.new(street: "123 Rua das Acácias", city: nil) }

      it "raises an ArgumentError" do
        expect { service.call }.to raise_error(ArgumentError, "street and city are required")
      end
    end

    context "when the provider fails" do
      before { allow(provider).to receive(:geocode).and_raise(Geocoding::NotFoundError) }

      it "lets the error propagate" do
        expect { service.call }.to raise_error(Geocoding::NotFoundError)
      end
    end
  end

  describe ".call" do
    it "uses Nominatim by default" do
      allow(Geocoding::NominatimProvider).to receive(:new).and_return(provider)
      allow(provider).to receive(:geocode).and_return(result)

      expect(described_class.call(address)).to eq(result)
    end
  end
end
