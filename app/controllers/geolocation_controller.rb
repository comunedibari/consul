class GeolocationsController < ApplicationController

    load_and_authorize_resource
    respond_to :html, :js

end