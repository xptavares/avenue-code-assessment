require "rails_helper"

RSpec.describe Geocoding::NominatimProvider do
  subject(:provider) { described_class.new }

  let(:address) do
    Geocoding::Address.new(street: "123 Rua das Acácias", city: "Vila Esperança", country: "Brasil")
  end
  let(:search_url) { "https://nominatim.openstreetmap.org/search" }

  def stub_search(status: 200, body: [])
    stub_request(:get, search_url)
      .with(
        query: hash_including(street: "123 Rua das Acácias", city: "Vila Esperança", country: "Brasil"),
        headers: { "User-Agent" => described_class::USER_AGENT }
      )
      .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  describe "#geocode" do
    context "when the address is found" do
      before do
        stub_search(body: [ { lat: "-10.5432", lon: "-40.2109", address: { postcode: "12345-678" } } ])
      end

      it "returns the coordinates and postal code" do
        expect(provider.geocode(address)).to have_attributes(latitude: -10.5432, longitude: -40.2109, postal_code: "12345-678")
      end
    end

    context "when the result has no postal code" do
      before { stub_search(body: [ { lat: "-10.5432", lon: "-40.2109", address: {} } ]) }

      it "returns a nil postal code" do
        expect(provider.geocode(address).postal_code).to be_nil
      end
    end

    context "when the address is not found" do
      before { stub_search(body: []) }

      it "raises a NotFoundError" do
        expect { provider.geocode(address) }.to raise_error(Geocoding::NotFoundError, /No results found for 123 Rua/)
      end
    end

    context "when Nominatim returns an error status" do
      before { stub_search(status: 503) }

      it "raises a Geocoding::Error" do
        expect { provider.geocode(address) }.to raise_error(Geocoding::Error, /Nominatim request failed/)
      end
    end

    context "when the request times out" do
      before { stub_request(:get, search_url).with(query: hash_including({})).to_timeout }

      it "raises a Geocoding::Error" do
        expect { provider.geocode(address) }.to raise_error(Geocoding::Error, /Nominatim request failed/)
      end
    end
  end
end
