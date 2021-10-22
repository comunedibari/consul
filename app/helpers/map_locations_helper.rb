module MapLocationsHelper

  def item_with_maplocation_count(items)
    val = 0
    items.each do |item|
      if  item.map_location
        val= val+1
      end 
    end
    val
  end

  def map_location_available?(map_location)
    map_location.present? && map_location.available?
  end

  def map_location_latitude(map_location)
    map_location.present? && map_location.latitude.present? ? map_location.latitude : Setting["map_latitude",User.pon_id]
  end

  def map_location_longitude(map_location)
    map_location.present? && map_location.longitude.present? ? map_location.longitude : Setting["map_longitude",User.pon_id]
  end

  def map_location_zoom(map_location)
    map_location.present? && map_location.zoom.present? ? map_location.zoom : Setting["map_zoom",User.pon_id]
  end

  def map_location_input_id(prefix, attribute)
    "#{prefix}_map_location_attributes_#{attribute}"
  end

  def map_location_remove_marker_link_id(map_location)
    "remove-marker-link-#{dom_id(map_location)}"
  end

  def render_map(map_location, parent_class, editable, remove_marker_label, geo_coding_addr=nil, investments_coordinates=nil)
    map_location = MapLocation.new if map_location.nil?
    addressPoints = []
    
    map = content_tag_for :div,
                          map_location,
                          class: "map",
                          data: prepare_map_settings(map_location, editable, parent_class, addressPoints, geo_coding_addr, investments_coordinates)
    map += map_location_remove_marker(map_location, remove_marker_label) if editable
    map
  end

  def render_map_user(map_location,parent_class, editable, remove_marker_label, geo_coding_addr=nil, investments_coordinates=nil)
    map_location = MapLocation.new if map_location.nil?
    addressPoints = []
    
    map = content_tag_for :div,
                          map_location,
                          class: "map",
                          #style: "display: none;",
                          data: prepare_map_settings_user(map_location, editable, parent_class, addressPoints, geo_coding_addr, investments_coordinates)
    map += map_location_remove_marker(map_location, remove_marker_label) if editable
    map
  end

  def render_heatmap(map_location,object, parent_class, editable, remove_marker_label, investments_coordinates=nil)
    map_location = MapLocation.new if map_location.nil?
    addressPoints = object.geo_hot_score
    map = content_tag_for :div,
                          map_location,
                          class: "map",
                          data: prepare_map_settings(map_location, editable, parent_class, addressPoints, investments_coordinates)
    map += map_location_remove_marker(map_location, remove_marker_label) if editable
    map
  end


  #nuova
  def render_simple_heatmap(map_location, parent_class, editable, remove_marker_label, investments_coordinates=nil)
    map_location = MapLocation.new if map_location.nil?
    addressPoints = nil
    map = content_tag_for :div,
                          map_location,
                          class: "map",
                          data: prepare_map_settings(map_location, editable, parent_class, addressPoints, investments_coordinates)
    map += map_location_remove_marker(map_location, remove_marker_label) if editable
    map
  end



  def map_location_remove_marker(map_location, text)
    content_tag :div, class: "margin-bottom" do
      content_tag :a,
                  id: map_location_remove_marker_link_id(map_location),
                  href: "#",
                  class: "js-location-map-remove-marker location-map-remove-marker" do
        text
      end
    end
  end

  def map_location_search(label_button)
    content_tag :div, class: "" do
      content_tag :a,
                  id: "search_geo",
                  href: "#",
                  style: "padding: 12px",                  
                  class: "btn btn-primary icon-search ml-3" do
                    " "+label_button
                  end
    end
  end

  private

  def prepare_map_settings(map_location, editable, parent_class,addressPoints,geocoding_adrr = nil, investments_coordinates=nil)
    options = {
      map: "",
      map_center_latitude: map_location_latitude(map_location),
      map_center_longitude: map_location_longitude(map_location),
      map_zoom: map_location_zoom(map_location),
      map_tiles_provider: Rails.application.secrets.map_tiles_provider,
      map_tiles_provider_attribution: Rails.application.secrets.map_tiles_provider_attribution,
      marker_editable: editable,
      marker_remove_selector: "##{map_location_remove_marker_link_id(map_location)}",
      geo_coding: "#search_geo",
      geo_coding_addr: geocoding_adrr,
      latitude_input_selector: "##{map_location_input_id(parent_class, 'latitude')}",
      longitude_input_selector: "##{map_location_input_id(parent_class, 'longitude')}",
      zoom_input_selector: "##{map_location_input_id(parent_class, 'zoom')}",
      marker_investments_coordinates: investments_coordinates,
      apikey_google: Rails.application.config.apikey_google
    }
    if addressPoints != nil && addressPoints.length > 0   #mia
      options[:addressPoints] = addressPoints
    end

    if addressPoints != nil
      options[:marker_latitude] = map_location.latitude if map_location.latitude.present?
      options[:marker_longitude] = map_location.longitude if map_location.longitude.present?
    elsif pon_count > 1
      options[:marker_latitude] = Setting["map_latitude",User.pon_id]
      options[:marker_longitude] = Setting["map_longitude",User.pon_id]
    elsif pon_count == 1
      options[:marker_latitude] = Setting["map_latitude",0]
      options[:marker_longitude] = Setting["map_longitude",0]
    end

    options
  end

  def prepare_map_settings_user(map_location, editable, parent_class,addressPoints,geocoding_adrr = nil, investments_coordinates=nil)
    options = {
      map: "",
      map_center_latitude: map_location_latitude(map_location),
      map_center_longitude: map_location_longitude(map_location),
      map_zoom: map_location_zoom(map_location),
      map_tiles_provider: Rails.application.secrets.map_tiles_provider,
      map_tiles_provider_attribution: Rails.application.secrets.map_tiles_provider_attribution,
      marker_editable: editable,
      marker_remove_selector: "##{map_location_remove_marker_link_id(map_location)}",
      marker_remove_selector_user: "#user_marker",      
      geo_coding: "#search_geo",
      geo_coding_addr: geocoding_adrr,
      latitude_input_selector: "##{map_location_input_id(parent_class, 'latitude')}",
      longitude_input_selector: "##{map_location_input_id(parent_class, 'longitude')}",
      zoom_input_selector: "##{map_location_input_id(parent_class, 'zoom')}",
      marker_investments_coordinates: investments_coordinates,
      apikey_google: Rails.application.config.apikey_google,
      parent_class: parent_class
    }
    if addressPoints != nil && addressPoints.length > 0   #mia
      options[:addressPoints] = addressPoints
    end

    if addressPoints != nil
      options[:marker_latitude] = map_location.latitude if map_location.latitude.present?
      options[:marker_longitude] = map_location.longitude if map_location.longitude.present?
    end

    options
  end

end
