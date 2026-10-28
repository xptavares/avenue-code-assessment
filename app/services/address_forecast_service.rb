class AddressForecastService < BaseService
  CACHE_TTL = 30.minutes

  Result = Data.define(:forecast, :cached, :fetched_at) do
    def expires_at
      fetched_at + CACHE_TTL
    end
  end

  def initialize(address, geocoder: GeocodingService, forecaster: ForecastService, cache: Rails.cache)
    @address = address
    @geocoder = geocoder
    @forecaster = forecaster
    @cache = cache
  end

  def call
    # Prefer the postal code the user typed so a cache hit skips geocoding entirely
    postal_code = @address.postalcode || location.postal_code
    return Result.new(**fresh_entry, cached: false) if postal_code.nil?

    cached = true
    entry = @cache.fetch(cache_key(postal_code), expires_in: CACHE_TTL) do
      cached = false
      fresh_entry
    end

    Result.new(**entry, cached:)
  end

  private

  def location
    @location ||= @geocoder.call(@address)
  end

  def fresh_entry
    { forecast: @forecaster.call(latitude: location.latitude, longitude: location.longitude), fetched_at: Time.current }
  end

  def cache_key(postal_code)
    "forecast/#{postal_code.gsub(/[^[:alnum:]]/, "").upcase}"
  end
end
