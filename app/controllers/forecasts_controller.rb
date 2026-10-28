class ForecastsController < ApplicationController
  def show
    @address = Geocoding::Address.new(**Geocoding::Address.members.index_with { address_params[it] })
    result = AddressForecastService.call(@address)

    @forecast = result.forecast
    @cached = result.cached
    @fetched_at = result.fetched_at
    @expires_at = result.expires_at
    @today, *@next_days = @forecast.days
  rescue ArgumentError
    fail_with "Street and city are required.", :unprocessable_content
  rescue Geocoding::NotFoundError
    fail_with "We couldn't find that address. Check it and try again.", :not_found
  rescue Geocoding::Error, Forecast::Error => e
    Rails.logger.error("Forecast lookup failed: #{e.message}")
    fail_with "The forecast is unavailable right now. Please try again later.", :service_unavailable
  end

  private

  def address_params
    params.fetch(:address, {}).permit(*Geocoding::Address.members)
  end

  def fail_with(message, status)
    respond_to do |format|
      format.html { redirect_to root_path(address: address_params.to_h), alert: message }
      format.json { render json: { error: message }, status: }
    end
  end
end
