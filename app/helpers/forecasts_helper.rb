module ForecastsHelper
  def temperature(value)
    value.nil? ? "-" : "#{value.round}°C"
  end
end
