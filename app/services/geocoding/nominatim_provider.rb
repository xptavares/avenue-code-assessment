module Geocoding
  class NominatimProvider
    BASE_URL = "https://nominatim.openstreetmap.org".freeze
    # Nominatim's usage policy requires an identifying User-Agent
    USER_AGENT = "avenue-code-assessment".freeze

    def geocode(address)
      response = connection.get("/search", address.to_h.compact.merge(format: "jsonv2", addressdetails: 1, limit: 1))
      place = response.body.first
      raise NotFoundError, "No results found for #{address}" if place.nil?

      Result.new(
        latitude: place["lat"].to_f,
        longitude: place["lon"].to_f,
        postal_code: place.dig("address", "postcode")
      )
    rescue Faraday::Error => e
      raise Error, "Nominatim request failed: #{e.message}"
    end

    private

    def connection
      @connection ||= Faraday.new(BASE_URL, headers: { "User-Agent" => USER_AGENT }, request: { timeout: 5, open_timeout: 2 }) do |f|
        f.response :raise_error
        f.response :json
      end
    end
  end
end
