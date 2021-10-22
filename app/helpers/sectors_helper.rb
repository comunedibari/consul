module SectorsHelper

=begin  def progress_bar_percentage(sector)
    case sector.cached_votes_up
    when 0 then 0
    when 1..Sector.votes_needed_for_success then (sector.total_votes.to_f * 100 / Sector.votes_needed_for_success).floor
    else 100
    end
  end

  def supports_percentage(sector)
    percentage = (sector.total_votes.to_f * 100 / Sector.votes_needed_for_success)
    case percentage
    when 0 then "0%"
    when 0..0.1 then "0.1%"
    when 0.1..100 then number_to_percentage(percentage, strip_insignificant_zeros: true, precision: 1)
    else "100%"
    end
  end
=end
  def namespaced_sector_path(sector, options = {})
    @namespace_sector_path ||= namespace
    case @namespace_sector_path
    when "management"
      management_sector_path(sector, options)
    else
      sector_path(sector, options)
    end
  end

  def sectors_by_user(user = nil)
    if user
      v_user = user
    else
      v_user = current_user
    end

    sector_names = Array.new
    sectors_by_user = Sector.where(user_id: v_user.id).where(visible: true)
    #logger.debug " ***************************************************************"
    sectors_by_user.each do |sector|
      sector_names.push([sector.sector_type.name + ' - ' + sector.name.to_s, sector.id])
      #logger.debug " "+ sector.name.to_s
    end

    sector_names
  end

  def sectorsObject_by_user
    sectors_by_user = Sector.where(user_id: current_user.id)
  end

  def sector_select_options
    Sector.where(user_id: current_user.id).order(name: :asc).collect { |g| [g.name, g.id] }
  end

  def empty_recommended_sectors_message_text(user)
    if user.interests.any?
      t('proposals.index.recommendations.without_results')
    else
      t('proposals.index.recommendations.without_interests')
    end
  end

  def author_of_sector?(sector)
    author_of?(sector, current_user)
  end

  def sector_current_editable?(sector)
    current_user && sector.editable_by?(current_user)
  end

  def sectors_by_sector_type
    sectors = Sector.sector_type(params[:sector_type])
  end

  def sectors_minimal_view_path
    sectors_path(view: sectors_secondary_view)
  end

  def sectors_default_view?
    @view == "default"
  end

  def sectors_current_view
    @view
  end

  def sectors_secondary_view
    sectors_current_view == "default" ? "minimal" : "default"
  end

  def st_sector_modify?
    if params[:st].present?
      current_user and @sector.editable_by_with_st?(current_user, @sector.sector_id, params[:st])
    else
      current_user and @sector.editable_by?(current_user, @sector.sector_id)
    end
  end

  def param_approved
    case params[:approved]
    when "true"
      "Approva"
    when "false"
      "Respingi"
    when "modify"
      "Richiedi Integrazioni"
    else
      ""
    end
  end

  def buttons_current_filter
    case @current_filter
    when "new_adds"
      "Approva"
    when "false"
      "Respingi"
    when "modify"
      "Richiedi Integrazioni"
    else
      ""
    end
  end
end
