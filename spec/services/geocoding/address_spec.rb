require "rails_helper"

RSpec.describe Geocoding::Address do
  describe ".new" do
    it "defaults the optional fields to nil" do
      address = described_class.new(street: "123 Rua das Acácias", city: "Vila Esperança")

      expect(address).to have_attributes(state: nil, country: nil, postalcode: nil)
    end

    it "strips whitespace and turns blank values into nil" do
      address = described_class.new(street: "  123 Rua das Acácias ", city: "Vila Esperança", state: "  ")

      expect(address).to have_attributes(street: "123 Rua das Acácias", state: nil)
    end

    it "requires street and city" do
      expect { described_class.new(street: "123 Rua das Acácias") }.to raise_error(ArgumentError, /city/)
    end
  end

  describe "#to_s" do
    it "joins the present fields" do
      address = described_class.new(street: "123 Rua das Acácias", city: "Vila Esperança", postalcode: "12345-678")

      expect(address.to_s).to eq("123 Rua das Acácias, Vila Esperança, 12345-678")
    end
  end
end
