module SettingsHelper


  
  def feature?(name)
    setting["feature.#{name}"].presence
  end

  def service?(name)
      setting["service.#{name}"].presence
  end

  def description(name)
      setting["service_description.#{name}"]
  end
  
  def social(name)
    setting["service_social.#{name}"]
  end
  def service_social?(name)
    if current_user
      Setting.where(key: "service_social.#{name}").where("value = 'true' ").where(pon_id: User.pon_id).first.present?
    else
      return false
    end
  end

  def service_blocked?(name)
    !setting["service.#{name}"].presence && current_user && Setting.where(pon_id: current_user.pon_id).where(key: "service.#{name}").first.editable
  end

  def service_present?(name)
    sett_val = Setting.where(pon_id: User.pon_id).where(key: "service.#{name}").first
    !setting["service.#{name}"].presence && sett_val.editable && sett_val.value == ''
  end

  def setting
    @all_settings ||= Hash[ Setting.pon(User.pon_id).map{|s| [s.key, s.value.presence]} ]
  end

  def service_social_obj_pon?(name,obj)
    if !obj.nil? and !obj.pon_id.nil?
      Setting.where(key: "service_social.#{name}").where("value = 'true' ").where(pon_id: obj.pon_id).first.present?
    else
      return false
    end
  end
end
