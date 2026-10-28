json.address @address.to_s
json.cached @cached
json.fetched_at @fetched_at
json.expires_at @expires_at
json.current_temperature @forecast.current_temperature

json.days @forecast.days do |day|
  json.extract! day, :date, :high, :low, :precipitation_probability, :precipitation_sum

  json.hours day.hours do |hour|
    json.extract! hour, :time, :temperature, :precipitation_probability, :precipitation
  end
end
