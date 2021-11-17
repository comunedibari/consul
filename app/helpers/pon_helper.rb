module PonHelper

  def get_pons
    @pons = Pon.where("id > 0").all
  end

  def get_pon_100
    @pon_100 = Pon.where("id = 100").first
  end

  def pon_count
    Pon.where("id > 0").count
  end

  def default_path
    def_pon= Rails.application.config.default_pon
    list_pons = pon_active
    if list_pons.count > 1
      r_path =  root_path(:pon_id => def_pon)
    else
      r_path =  root_path
    end
    r_path
  end

  def pon_name(id)
    Pon.where("id = #{id}").first
  end

  def pon_for_service(service)
    @serv_pon = Setting.where("key = 'service.#{service}' and value = 'true' and pon_id > 0").all
  end

  def pon_actived
    connection = ActiveRecord::Base.connection
    #sql = "select p.id, p.name, count(s.id), p.html_map_coordinates from pons as p left join settings as s on s.pon_id = p.id  and s.value = 'true' and s.key like 'service.%' where p.id > 0 and p.id < 100 group by p.id, p.name order by p.name asc; "
    sql = "select p.id, p.name, count(s.id), p.html_map_coordinates from pons as p left join settings as s on s.pon_id = p.id  and s.value = 'true' and s.key like 'service.%' where p.id > 0 group by p.id, p.name order by p.name asc; "
    @val = connection.exec_query(sql)
  end

  def pon_active
    connection = ActiveRecord::Base.connection
    sql = "select p.id, p.name from pons as p join settings as s on s.pon_id = p.id  and s.value = 'true' and s.key like 'service.%' where p.id > 0 group by p.id, p.name order by p.name asc;"
    connection.exec_query(sql)
  end

  def check_service_active
    service?(:debates) ||  service?(:proposals) ||  service?(:works) ||  service?(:chances) ||  service?(:reportings) ||  service?(:processes) ||  service?(:events) ||  service?(:polls) ||  service?(:collaboration) ||  service?(:crowdfundings) ||  service?(:assets) ||  service?(:third_sector_platform)
  end

end