class GeocodingService < BaseService
  def initialize(address, provider: Geocoding::NominatimProvider.new)
    @address = address
    @provider = provider
  end

  def call
    raise ArgumentError, "street and city are required" if @address.street.nil? || @address.city.nil?

    @provider.geocode(@address)
  end
end
