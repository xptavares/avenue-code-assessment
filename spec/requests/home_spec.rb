require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "renders the address form" do
      get root_path

      expect(response.body).to include('name="address[street]"', 'name="address[city]"', 'name="address[postalcode]"')
    end

    it "keeps the submitted values in the form" do
      get root_path, params: { address: { street: "123 Rua das Acácias", city: "Vila Esperança" } }

      expect(response.body).to include('value="123 Rua das Acácias"', 'value="Vila Esperança"')
    end

    it "submits the form to the forecast page" do
      get root_path

      expect(response.body).to include(%(action="#{forecast_path}"))
    end

    it "renders both tabs" do
      get root_path

      expect(response.body).to include("Server-rendered", "JSON API")
    end

    it "wires the JSON API form to the forecast controller" do
      get root_path

      expect(response.body).to include('data-action="forecast#submit"', 'id="json_address_street"')
    end
  end
end
