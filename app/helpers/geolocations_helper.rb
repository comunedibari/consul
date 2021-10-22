module GeolocationsHelper

    def geo_location_latitude()
      Setting["map_latitude",User.pon_id]
    end

    def geo_location_longitude()
      Setting["map_longitude",User.pon_id]
    end

    def geo_location_zoom()
      Setting["map_zoom",User.pon_id]
    end

    def render_geolocation(object, parent_class,parent_spec = nil)
        geolocation_arr = parseObjectArray (object)
        #geolocation = Geolocation.new
        geolocation = geolocation_arr[0] ? geolocation_arr[0] : MapLocation.new
        markers = prepare_geolocation_marker(geolocation_arr,parent_class,parent_spec)
        map = content_tag_for :div,
                              geolocation,
                              class: "map",
                              data: prepare_geolocation_settings(parent_class,markers)
        map
    end

    def render_geojson(geolocation_arr, parent_class,parent_spec = nil)
      #geolocation = Geolocation.new
      geolocation = geolocation_arr.count > 0 && geolocation_arr[0].map_location ? geolocation_arr[0].map_location : MapLocation.new
      markers = prepare_geojson_marker(geolocation_arr,parent_class,parent_spec)
      map = content_tag_for :div,
                            geolocation,
                            class: "map",
                            data: prepare_geojson_settings(parent_class,markers)
      map
  end

    private

      def prepare_geolocation_marker(geolocation_arr,parent_class,parent_spec = nil)
        classes = %w[proposal crowdfunding debate event legislation_process collaboration_agreement reporting sector asset]
        marker_arr = Array.new
        if !parent_spec
          parent_spec = parent_class
        end
        for i in 0..geolocation_arr.count-1 do

            if classes.include? parent_class
              url = send("json_data_#{parent_class}_path",geolocation_arr[i]['localizable_id'])
            else
              url = parent_class
            end
            coord = [geolocation_arr[i].longitude,geolocation_arr[i].latitude,geolocation_arr[i][parent_class+'_id'],parent_spec,url]
            marker_arr[i] = Array.new(coord)
        end
        marker_arr 
      end


      def prepare_geojson_marker(geolocation_arr,parent_class,parent_spec = nil)
        #marker_arr = Array.new(geolocation_arr.count) {Array.new(2)}
        marker_arr = Array.new
        if !parent_spec
          parent_spec = parent_class
        end
        for i in 0..geolocation_arr.count-1 do
            #coord = [geolocation_arr[i].lon,geolocation_arr[i].lat,geolocation_arr[i].localizable_id,geolocation_arr[i].localizable_type]
            img_url = geolocation_arr[i].reporting_type.imageMarker
            if !img_url.upcase.starts_with?('HTTP')
              img_url_arr = image_tag("reporting_type/"+geolocation_arr[i].reporting_type.imageMarker, class: "card_icon").split('src="')
              img_url=img_url_arr[1].split('" alt')[0]
            end     
            url = json_data_reporting_path(geolocation_arr[i]['id'])
            coord = [geolocation_arr[i].map_location.longitude,geolocation_arr[i].map_location.latitude,geolocation_arr[i].map_location[parent_class+'_id'],parent_spec,img_url,geolocation_arr[i].title,url]
            
            
            #coord = [geolocation_arr[i].lon,geolocation_arr[i].lat]
            marker_arr[i] = Array.new(coord)
            #marker_arr[i][0] = geolocation_arr[i].lon
            #marker_arr[i][1] = geolocation_arr[i].lat
            #logger.debug "--- marker_arr " + marker_arr[i].to_s
        end
        marker_arr 
      end

      def prepare_geolocation_settings(parent_class,markers)
        options = {
          map: "",
          map_center_latitude: geo_location_latitude(),
          map_center_longitude: geo_location_longitude(),
          map_zoom: geo_location_zoom(),
          map_tiles_provider: Rails.application.secrets.map_tiles_provider,
          map_tiles_provider_attribution: Rails.application.secrets.map_tiles_provider_attribution
        }
        options[:markers] = markers
        #options[:marker_latitude] = 41.10742460183232 #map_location.latitude if map_location.latitude.present?
        #options[:marker_longitude] =  16.853713989257812 #map_location.longitude if map_location.longitude.present?
        options
      end   
      
      def prepare_geojson_settings(parent_class,geojson_data)
        options = {
          map: "",
          map_center_latitude: geo_location_latitude(),
          map_center_longitude: geo_location_longitude(),
          map_zoom: geo_location_zoom(),
          map_tiles_provider: Rails.application.secrets.map_tiles_provider,
          map_tiles_provider_attribution: Rails.application.secrets.map_tiles_provider_attribution
        }
        options[:layer_reporting] = geojson_data
        #options[:marker_latitude] = 41.10742460183232 #map_location.latitude if map_location.latitude.present?
        #options[:marker_longitude] =  16.853713989257812 #map_location.longitude if map_location.longitude.present?
        options
      end
      
      def parseObjectArray (objects)
          geolocation_arr = []
          objects.each do |obj|
              if  obj.map_location
                  geolocation = obj.map_location
                  geolocation_arr.push(geolocation) 
              end 
          end
          geolocation_arr
      end
end
