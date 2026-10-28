class ForecastsController < ApplicationController
  def show
    @address = Geocoding::Address.new(**Geocoding::Address.members.index_with { address_params[it] })
    result = AddressForecastService.call(@address)

    @forecast = result.forecast
    @cached = result.cached
    @today, *@next_days = @forecast.days
  rescue ArgumentError
    back_to_form "Street and city are required."
  rescue Geocoding::NotFoundError
    back_to_form "We couldn't find that address. Check it and try again."
  rescue Geocoding::Error, Forecast::Error => e
    Rails.logger.error("Forecast lookup failed: #{e.message}")
    back_to_form "The forecast is unavailable right now. Please try again later."
  end

  private

  def address_params
    params.fetch(:address, {}).permit(*Geocoding::Address.members)
  end

  def back_to_form(message)
    redirect_to root_path(address: address_params.to_h), alert: message
  end
end
