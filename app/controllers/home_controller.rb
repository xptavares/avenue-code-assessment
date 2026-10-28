class HomeController < ApplicationController
  def index
    @address = params.fetch(:address, {}).permit(*Geocoding::Address.members)
  end
end
