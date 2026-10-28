class AddressForecastService < BaseService
  CACHE_TTL = 30.minutes

  Result = Data.define(:forecast, :cached)

  def initialize(address, geocoder: GeocodingService, forecaster: ForecastService, cache: Rails.cache)
    @address = address
    @geocoder = geocoder
    @forecaster = forecaster
    @cache = cache
  end

  def call
    # Prefer the postal code the user typed so a cache hit skips geocoding entirely
    postal_code = @address.postalcode || location.postal_code
    return Result.new(forecast: fetch_forecast, cached: false) if postal_code.nil?

    cached = true
    forecast = @cache.fetch(cache_key(postal_code), expires_in: CACHE_TTL) do
      cached = false
      fetch_forecast
    end

    Result.new(forecast:, cached:)
  end

  private

  def location
    @location ||= @geocoder.call(@address)
  end

  def fetch_forecast
    @forecaster.call(latitude: location.latitude, longitude: location.longitude)
  end

  def cache_key(postal_code)
    "forecast/#{postal_code.gsub(/[^[:alnum:]]/, "").upcase}"
  end
end
