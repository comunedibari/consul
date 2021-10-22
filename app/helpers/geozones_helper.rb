module GeozonesHelper

  def geozone_name(geozonable)
    geozonable.geozone ? geozonable.geozone.name : t("geozones.none")
  end

  def geozone_select_options
    Geozone.by_user_pon.order(name: :asc).collect { |g| [ g.name, g.id ] }
  end

  def geozone_name_from_id(g_id)
    @all_geozones ||= Geozone.by_user_pon.collect{ |g| [ g.id, g.name ] }.to_h
    @all_geozones[g_id] || t("geozones.none")
  end

end
