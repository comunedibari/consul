App.Map =

  initialize: ->
    maps = $('*[data-map]')

    if maps.length > 0
      $.each maps, (index, map) ->
        App.Map.initializeMap map

    $('.js-toggle-map').on
        click: ->
          App.Map.toogleMap()


  initializeMap: (element) ->

    mapCenterLatitude        = $(element).data('map-center-latitude')
    mapCenterLongitude       = $(element).data('map-center-longitude')
    markerLatitude           = $(element).data('marker-latitude')
    markerLongitude          = $(element).data('marker-longitude')
    zoom                     = $(element).data('map-zoom')
    mapTilesProvider         = $(element).data('map-tiles-provider')
    mapAttribution           = $(element).data('map-tiles-provider-attribution')
    latitudeInputSelector    = $(element).data('latitude-input-selector')
    longitudeInputSelector   = $(element).data('longitude-input-selector')
    zoomInputSelector        = $(element).data('zoom-input-selector')
    removeMarkerSelector     = $(element).data('marker-remove-selector')
    removeMarkerSelectorUser     = $(element).data('marker-remove-selector-user')
    geocoding                = $(element).data('geo-coding')
    geocoding_addr           = $(element).data('geo-coding-addr')
    addMarkerInvestments     = $(element).data('marker-investments-coordinates')
    editable                 = $(element).data('marker-editable')
    markers                  = $(element).data('markers')
    layer_reporting          = $(element).data('layer-reporting')
    layer_debate             = $(element).data('layer-debate')
    img_urls_array           = $(element).data('img-urls-array')
    addressPoints            = $(element).data('addresspoints')
    marker                   = null;
    apikey                   = $(element).data('apikey-google')
    parent_class                   = $(element).data('parent-class')
    markerIcon               = L.divIcon(
                                  className: 'map-marker'
                                  iconSize:     [30, 30]
                                  iconAnchor:   [15, 40]
                                  html: '<div class="map-icon"></div>')

    #ripulisce la form relativa alla mappa
    #if !editable   
    $('.js-toggle-map-user').on
        click: ->
          if marker
            map.removeLayer(marker)
            marker = null;
            clearFormfields()
          #App.Map.toogleMapUser()
          $('.map').toggle()
          $('.geoloc-user').toggle()
          if editable
            $(removeMarkerSelector).toggle()
            $(".moderation-description").toggle()
            $("#account_public_map").prop( "checked", false );
            


    addLayerGeojson = (layer_reporting) ->
      #myStyle = {"color": "#ff7800","weight": 5,"opacity": 0.65}
      clusters = new L.MarkerClusterGroup
      if layer_reporting
        #L.geoJSON(markers,{icon: markerIcon}).addTo(map)
        for i in [0..layer_reporting.length-1]
          markerIconGeojson = L.icon(iconUrl:layer_reporting[i][4])  
          marker = createMarkerGeojson(layer_reporting[i][1], layer_reporting[i][0],markerIconGeojson)
          #console.log(layer_geojson.features[i].geometry.coordinates[0])
          marker.options['id'] = layer_reporting[i][2]
          marker.options['type'] = layer_reporting[i][3]
          marker.options['title'] = layer_reporting[i][5]
          marker.options['url'] = layer_reporting[i][6]
          marker.on 'click', openMarkerPopup
          clusters.addLayer(marker)
        map.addLayer(clusters)
      return

    addLayerGeojsonDebate = (layer_debate) ->
      #myStyle = {"color": "#ff7800","weight": 5,"opacity": 0.65}
      clusters = new L.MarkerClusterGroup
      if layer_debate
        #L.geoJSON(markers,{icon: markerIcon}).addTo(map)
        for i in [0..layer_debate.length-1]
          markerIconGeojson = L.icon(iconUrl:layer_debate[i][4])  
          #console.log markerIconGeojson
          #console.log layer_debate[i][4]
          #markerStyle = {"color": layer_debate[i][4],"weight": 5,"opacity": 0.65}
          marker = createMarkerGeojsonDebate(layer_debate[i][1], layer_debate[i][0],markerIconGeojson)
          #console.log(layer_geojson.features[i].geometry.coordinates[0])
          marker.options['id'] = layer_debate[i][2]
          #marker.options['type'] = layer_debate[i][3]
          marker.options['title'] = layer_debate[i][5]
          marker.options['url'] = layer_debate[i][6]
          marker.on 'click', openMarkerPopup
          clusters.addLayer(marker)
        map.addLayer(clusters)
      return

    createMarkerGeojson = (latitude, longitude,markerIconGeojson) ->      
      markerLatLng  = new (L.LatLng)(latitude, longitude)
      marker  = L.marker(markerLatLng, {icon: markerIconGeojson , draggable: editable })
      if editable
        marker.on 'dragend', updateFormfields
      return marker

    createMarkerGeojsonDebate = (latitude, longitude, markerIconGeojson) ->
      markerLatLng  = new (L.LatLng)(latitude, longitude)
      marker  = L.marker(markerLatLng, {icon: markerIconGeojson , draggable: editable })
      if editable
        marker.on 'dragend', updateFormfields
      return marker

    addLayerMarkers = (markers) ->
      #myStyle = {"color": "#ff7800","weight": 5,"opacity": 0.65}
      clusters = new L.MarkerClusterGroup
      if markers
        #L.geoJSON(markers,{icon: markerIcon}).addTo(map)
        for i in [0..markers.length-1]
          marker = createMarker_for_cluster(markers[i][1], markers[i][0])
          marker.options['id'] = markers[i][2]
          marker.options['type'] = markers[i][3]
          marker.options['url'] = markers[i][4]
          marker.on 'click', openMarkerPopup
          clusters.addLayer(marker)
        map.addLayer(clusters)
      return

    createMarker_for_cluster = (latitude, longitude) ->
      markerLatLng  = new (L.LatLng)(latitude, longitude)
      marker  = L.marker(markerLatLng, { icon: markerIcon, draggable: editable })
      if editable
        marker.on 'dragend', updateFormfields
      #marker.addTo(map)
      return marker

    createMarker = (latitude, longitude) ->
      markerLatLng  = new (L.LatLng)(latitude, longitude)
      marker  = L.marker(markerLatLng, { icon: markerIcon, draggable: editable })
      if editable
        marker.on 'dragend', updateFormfields
      marker.addTo(map)
      return marker

    removeMarker = (e) ->
      e.preventDefault()
      if marker
        map.removeLayer(marker)
        marker = null;
      clearFormfields()
      return

    showNotice = () ->
      $('#no-text-insert').removeClass('hide')

    hideNotice = () ->
      $('#no-text-insert').addClass('hide')

    ctrl_key = (e) ->
      if (e.which == 13) 
        e.preventDefault()
        $(geocoding).trigger('click');

    geocode_address = (e) ->
      e.preventDefault()
      hideNotice()
      address = $(geocoding_addr).val()
      if address.length == 0
        showNotice()
        return
      $.ajax 'https://nominatim.openstreetmap.org/?format=json&addressdetails=1&q='+address+'&format=json&limit=1',
          type: 'GET'
          dataType: 'json'
          success: (data) ->
            if data.length <= 0 
              if apikey.length > 0
                google_geocode_address(address,e)
              else
                alert "Geocoding non disponibile"
                removeMarker (e)
            else
              lat = data[0].lat
              lng = data[0].lon                        
              if marker
                map.removeLayer(marker)
                marker = null;
                clearFormfields()
              createMarker(lat,lng);
              map.setView([lat, lng], 18);
          error: () ->
            if apikey.length > 0
                google_geocode_address(address)
            else
              alert "Problemi di connessione"
      return


    google_geocode_address = (address,e) ->
      $.ajax 'https://maps.googleapis.com/maps/api/geocode/json?address='+address+'&key='+apikey,
          type: 'GET'
          dataType: 'json'
          success: (data) ->
            if data.status == "ZERO_RESULTS" or data.status == "OVER_QUERY_LIMIT"
              alert "Geocoding non disponibile"
              removeMarker (e)
            else
              lat = data.results[0].geometry.location.lat
              lng = data.results[0].geometry.location.lng                        
              if marker
                map.removeLayer(marker)
                marker = null;
                clearFormfields()
              createMarker(lat,lng);
              map.setView([lat, lng], 18);
          error: () ->
            alert "Problemi di connessione"
      return

      
    moveOrPlaceMarker = (e) ->
      if marker
        marker.setLatLng(e.latlng)
      else
        marker = createMarker(e.latlng.lat, e.latlng.lng)

      updateFormfields()
      return

    updateFormfields = ->
      $(latitudeInputSelector).val marker.getLatLng().lat
      $(longitudeInputSelector).val marker.getLatLng().lng
      $(zoomInputSelector).val map.getZoom()
      return

    clearFormfields = ->
      $(latitudeInputSelector).val ''
      $(longitudeInputSelector).val ''
      $(zoomInputSelector).val ''
      $('#account_address').val ''
      return

    openMarkerPopup = (e) ->
      marker = e.target     
      
      if marker.options['type'] == 'investment'   
         $.ajax 'investments/' + marker.options['id'] + '/json_data',
          type: 'GET'
          dataType: 'json'
          success: (data) ->
            e.target.bindPopup(getPopupContentOld(data)).openPopup()
      else
        $.ajax marker.options['url'],
          type: 'GET'
          dataType: 'json'
          success: (data) ->
            e.target.bindPopup(getPopupContentStandard(data)).openPopup()


    getPopupContentOld = (data) ->
      content = "<a href='/budgets/#{data['budget_id']}/investments/#{data['investment_id']}'>#{data['investment_title']}</a>"
      return content


    getPopupContentStandard = (data) ->
      content = "<a href='#{data['url']}'>#{data['title']}</a>"
      return content
    

    mapCenterLatLng  = new (L.LatLng)(mapCenterLatitude, mapCenterLongitude)
    map              = L.map(element.id,{minZoom: 8, maxZoom: 18}).setView(mapCenterLatLng, zoom)
    L.tileLayer(mapTilesProvider, attribution: mapAttribution).addTo map

    if editable
      lc = new	 L.control.locate(
            position:'topright',
            drawCircle:true,
            drawMarker:true,
            showPopup:false,
            icon:'fa fa-map-marker',
            setView:'always',
            flyTo:true,
            cacheLocation:true,
            markerClass:L.CircleMarker
          ).addTo(map)


    onLocationFound = (e) ->
        locate_val = e.latlng;
        if marker 
          map.removeLayer(marker)
        console.log("val "+ locate_val)
        marker = null;
        createMarker(locate_val['lat'],locate_val['lng']);
        updateFormfields();
        map.stopLocate();
        
    map.on('locationfound', onLocationFound);

    new L.Control.Fullscreen({
    title: {
        'false': 'View Fullscreen',
        'true': 'Exit Fullscreen'
    }
    }).addTo(map)

    #console.log parent_class
    if markerLatitude && markerLongitude && !addMarkerInvestments      
      marker  = createMarker(markerLatitude, markerLongitude)

    if editable
      $(removeMarkerSelector).on 'click', removeMarker
      $(geocoding).on 'click', geocode_address
      $(geocoding_addr).on 'keypress', ctrl_key
      $(geocoding).on 'keypress', ctrl_key
      map.on    'zoomend', updateFormfields
      map.on    'click',   moveOrPlaceMarker  
    else if parent_class == "user"
      $(geocoding).on 'click', geocode_address
      #$(removeMarkerSelectorUser).on 'click', removeMarker

    if addMarkerInvestments
      for i in addMarkerInvestments
        if App.Map.validCoordinates(i)
          marker = createMarker(i.lat, i.long)
          marker.options['id'] = i.investment_id
          marker.on 'click', openMarkerPopup

    if markers
     addLayerMarkers(markers)

    if layer_reporting
     addLayerGeojson(layer_reporting)

    if layer_debate
      addLayerGeojsonDebate(layer_debate)
      legend = L.control(position: 'bottomright')

      legend.onAdd = (map) ->
        div = L.DomUtil.create('div', 'info legend') 
        labels = []

        labels.push '<p><b style="font-size: 15px;">Stato dei tavoli</b></p><br>
          <p style="clear: both;"><strong style="font-size: 12px;"><img style="float: left;" src="'+img_urls_array[0]+'" alt="pin1" width="32" height="32" /></strong>Aperti</p>
          <p style="clear: both;"><strong style="font-size: 12px;"><img style="float: left;" src="'+img_urls_array[1]+'" alt="pin1" width="32" height="32" /></strong>Proposti</p>
          <p style="clear: both;"><strong style="font-size: 12px;"><img style="float: left;" src="'+img_urls_array[2]+'" alt="pin1" width="32" height="32" /></strong>Chiusi</p>'
  
        div.innerHTML = labels.join('<br>')
        div

      legend.addTo(map)


    if addressPoints
      map.options.maxZoom = 16
      map.options.minZoom = 6
      #L.heatLayer(addressPoints).addTo(map);
      L.heatLayer(addressPoints,{ maxZoom: 15, max: 100, blur: 50,radius: 30, minOpacity: 20, gradient: { 0.2: 'green', 0.7: 'yellow', 0.9: 'orange',  1: 'red'}}).addTo(map);
      #,gradient: {0.4: 'green', 0.6: 'yellow', 0.8: 'orange',  1: 'red'}}).addTo(map);      
      legend = L.control(position: 'bottomright')

      getColor = (d) ->
        if d >= 100  then '#DB3A12' 
        else if d > 75 then '#fc830f' 
        else if d > 50 then '#ffe93c' 
        else if d > 25 then '#bccd58' 
        else if d > 10 then '#799842' 
        else if d > 0 then '#799842' 
        else '#A4A7E0'

      legend.onAdd = (map) ->
        div = L.DomUtil.create('div', 'info legend')
        grades = [
          0
          25
          50
          75
          100
          125
        ]
        gradesL = [
          'Basso'
          ''
          'Medio'
          ''
          'Alto'
        ]
        labels = []
        from = undefined
        to = undefined
        i = 0
        labels.push '<b style="font-size: 12px;">Grado di <br>interazione</b><br>'
        while i < gradesL.length
          from = grades[i]
          to = grades[i + 1]+'% '
          label = gradesL[i]
          #labels.push '<i style="background:' + getColor(from + 1) + '"></i> ' + from + (if to then '% &ndash; ' + to)
          labels.push '<i style="background:' + getColor(from + 1) + '"></i> ' + label
          i++
        
        div.innerHTML = labels.join('<br>')
        div

      legend.addTo(map)

  toogleMap: ->
      $('.map').toggle()
      $('.js-location-map-remove-marker').toggle()            
