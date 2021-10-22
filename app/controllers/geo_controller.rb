class GeoController < ApplicationController
  skip_authorization_check

  def geocode
    if params[:json_data] != nil
      # check if json_data is well formed
      render :json => 
      [
          {
              "place_id": "55567375",
              "licence": "Data © OpenStreetMap contributors, ODbL 1.0. http://www.openstreetmap.org/copyright",
              "osm_type": "way",
              "osm_id": "23580556",
              "boundingbox": [
                  "51.4828405",
                  "51.4847466",
                  "-0.6083937",
                  "-0.5999972"
              ],
              "lat": "51.48382",
              "lon": "-0.604132479198226",
              "display_name": "Windsor Castle, Moat Path, Clewer Within, Slopes Lodge, Eton, Windsor and Maidenhead, South East, England, SL4 1PB, United Kingdom",
              "class": "historic",
              "type": "castle",
              "importance": 0.60105687743994,
              "icon": "http://open.mapquestapi.com/nominatim/v1/images/mapicons/tourist_castle.p.20.png",
              "address": {
                  "castle": "Windsor Castle",
                  "path": "Moat Path",
                  "neighbourhood": "Clewer Within",
                  "suburb": "Slopes Lodge",
                  "town": "Eton",
                  "county": "Windsor and Maidenhead",
                  "state_district": "South East",
                  "state": "England",
                  "postcode": "SL4 1PB",
                  "country": "United Kingdom",
                  "country_code": "gb"
              }
          }
      ]
    else
      render :text => "KO"
    end  

  end

  def revgeocode
    if User.pon_id > 0
      redirect_to root_path
    else
      @pons = Pon.all
    end
  end

end

