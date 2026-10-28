require "rails_helper"

RSpec.describe ForecastsHelper, type: :helper do
  describe "#temperature" do
    it "rounds and adds the unit" do
      expect(helper.temperature(21.6)).to eq("22°C")
    end

    it "returns a dash when there is no value" do
      expect(helper.temperature(nil)).to eq("-")
    end
  end
end
