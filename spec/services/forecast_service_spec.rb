require "rails_helper"

RSpec.describe ForecastService do
  subject(:service) { described_class.new(latitude:, longitude:, provider:) }

  let(:provider) { instance_double(Forecast::OpenMeteoProvider) }
  let(:latitude) { -10.5432 }
  let(:longitude) { -40.2109 }
  let(:result) do
    Forecast::Result.new(current_temperature: 21.4, days: [ Forecast::Day.new(date: Date.new(2026, 1, 15), high: 27.0, low: 18.2) ])
  end

  describe "#call" do
    context "with valid coordinates" do
      before { allow(provider).to receive(:forecast).with(latitude:, longitude:).and_return(result) }

      it "returns the provider result" do
        expect(service.call).to eq(result)
      end
    end

    context "with a latitude out of range" do
      let(:latitude) { 91 }

      it "raises an ArgumentError" do
        expect { service.call }.to raise_error(ArgumentError, "latitude must be between -90 and 90")
      end
    end

    context "with a longitude out of range" do
      let(:longitude) { -180.5 }

      it "raises an ArgumentError" do
        expect { service.call }.to raise_error(ArgumentError, "longitude must be between -180 and 180")
      end
    end

    context "with a non-numeric coordinate" do
      let(:latitude) { "-10.5432" }

      it "raises an ArgumentError" do
        expect { service.call }.to raise_error(ArgumentError, /latitude/)
      end
    end

    context "when the provider fails" do
      before { allow(provider).to receive(:forecast).and_raise(Forecast::Error) }

      it "lets the error propagate" do
        expect { service.call }.to raise_error(Forecast::Error)
      end
    end
  end

  describe ".call" do
    it "uses Open-Meteo by default" do
      allow(Forecast::OpenMeteoProvider).to receive(:new).and_return(provider)
      allow(provider).to receive(:forecast).and_return(result)

      expect(described_class.call(latitude:, longitude:)).to eq(result)
    end
  end
end
