class ForecastService < BaseService
  def initialize(latitude:, longitude:, provider: Forecast::OpenMeteoProvider.new)
    @latitude = latitude
    @longitude = longitude
    @provider = provider
  end

  def call
    raise ArgumentError, "latitude must be between -90 and 90" unless within?(@latitude, 90)
    raise ArgumentError, "longitude must be between -180 and 180" unless within?(@longitude, 180)

    @provider.forecast(latitude: @latitude, longitude: @longitude)
  end

  private

  def within?(value, limit)
    value.is_a?(Numeric) && value.between?(-limit, limit)
  end
end
