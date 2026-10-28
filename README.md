# Weather Forecast

A Rails app that takes an address and shows the weather forecast for it.

It shows the current temperature, the high and low for today, the chance of rain by hour and the forecast for the next 6 days. Results are cached for 30 minutes by postal code, and the page tells you when the result came from the cache.

## Running it

You need Ruby 3.4.9 and PostgreSQL.

```
bin/setup
```

This installs the gems, creates the database and starts the server at http://localhost:3000. After the first time, use `bin/dev` to start it (it also runs the Tailwind watcher).

No API keys are needed.

### With Docker

If you don't have Ruby or PostgreSQL installed, you only need Docker:

```
docker compose up
```

The app runs at http://localhost:3000. To run the tests:

```
docker compose run --rm -e RAILS_ENV=test web bash -c "bin/rails db:prepare && bundle exec rspec"
```

## Tests

```
bundle exec rspec
bin/rubocop
```

The coverage report is saved in `coverage/index.html`.

## External APIs

- [Nominatim](https://nominatim.org/) (OpenStreetMap) to turn the address into latitude and longitude.
- [Open-Meteo](https://open-meteo.com/) to get the forecast for those coordinates.

Both are free and don't need an account, so anyone can clone the project and run it.

## How it works

```
address -> GeocodingService -> lat/lng -> ForecastService -> forecast
```

`AddressForecastService` puts the two together and handles the cache.

Each external API lives behind a provider (`Geocoding::NominatimProvider` and `Forecast::OpenMeteoProvider`). The services don't know which API is being used, so changing to another one means writing a new provider. It also makes the services easy to test with a fake provider.

The providers return plain objects (`Geocoding::Result`, `Forecast::Result`, `Forecast::Day`, `Forecast::Hour`) instead of the raw JSON, so the rest of the app doesn't depend on the API format.

## Cache

The forecast is saved in `Rails.cache` for 30 minutes using the postal code as the key. `12345-678` and `12345678` are the same key.

If the user typed a postal code, it is used directly, so a cache hit skips both API calls. If not, the app geocodes the address first and uses the postal code that Nominatim returns. If there is no postal code at all, the forecast is shown but not cached.

The cache also stores when the forecast was fetched, so the page can show "Fetched 12 minutes ago. Refreshes in 18 minutes."

In development the cache is in memory, so it resets when the server restarts. In production it uses Solid Cache.

## Why there are two search forms

The home page has two tabs with the same form:

- **Server-rendered**: the normal Rails way. The form goes to `/forecast` and Rails renders the result page.
- **JSON API**: the form is sent with `fetch` to the same `/forecast` URL asking for JSON, and the result is rendered on the home page with JavaScript (Stimulus).

I wanted to show both ways because they are both common in real projects. The point is that the backend is the same: one controller action (`ForecastsController#show`) answers HTML or JSON depending on what is asked, and both use the same services and the same cache. The JSON endpoint can also be used by any other client.

```
curl -g -H "Accept: application/json" "http://localhost:3000/forecast?address[street]=...&address[city]=..."
```

Errors come back as JSON with a status code: 422 when street or city is missing, 404 when the address is not found and 503 when one of the APIs fails.

## Decisions and limitations

- **The address form has separate fields.** At first I used a single text field, but Nominatim returns nothing when the address has things it doesn't know, like an apartment number, or when the parts are in a different order. Sending street, city, state, country and postal code separately works much better.
- **The cache key doesn't include the country.** Two countries can have the same postal code. I left the country out because it is free text ("Brasil" and "Brazil" would be different keys).
- **Nominatim allows 1 request per second.** That's fine for this project, and the cache helps, but a real app with more traffic would need a paid geocoding service or its own Nominatim server.
- **Temperatures are in Celsius.** Open-Meteo can return Fahrenheit by changing one parameter.
- **The JavaScript has no automated tests.** It would need system specs with a browser running in CI.

## Next steps

- **Use the browser location.** A "Use my location" button could get the coordinates with `navigator.geolocation`. The browser only gives latitude and longitude, so the app would need a reverse geocoding call (Nominatim has a `/reverse` endpoint) to find the postal code and keep using the same cache.
