module Geocoding
  Address = Data.define(:street, :city, :state, :country, :postalcode) do
    def initialize(street:, city:, state: nil, country: nil, postalcode: nil)
      super(**{ street:, city:, state:, country:, postalcode: }.transform_values { it.to_s.strip.presence })
    end

    def to_s
      to_h.values.compact.join(", ")
    end
  end
end
