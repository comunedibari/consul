module SearchHelper

  def official_level_search_options
    options_for_select((1..5).map { |i| [setting["official_level_#{i}_name"], i] },
                       params[:advanced_search].try(:[], :official_level))
  end

  def date_range_options
    options_for_select([
                           [t("shared.advanced_search.date_1"), 1],
                           [t("shared.advanced_search.date_2"), 2],
                           [t("shared.advanced_search.date_3"), 3],
                           [t("shared.advanced_search.date_4"), 4],
                           [t("shared.advanced_search.date_5"), 'custom']],
                       selected_date_range)
  end

  def date_range_options_for_event
    options_for_select([
                           #[t("shared.advanced_search.date_1"), 1],
                           #[t("shared.advanced_search.date_2"), 2],
                           #[t("shared.advanced_search.date_3"), 3],
                           #[t("shared.advanced_search.date_4"), 4],
                           [t("shared.advanced_search.date_10"), 10],
                           [t("shared.advanced_search.date_11"), 11],
                           [t("shared.advanced_search.date_12"), 12],
                           [t("shared.advanced_search.date_13"), 13],
                           [t("shared.advanced_search.date_5"), 'custom']],
                       selected_event_date_range)
  end

  # per reporting
  def reporting_type_options
    options_for_select([
                           [t("shared.advanced_search.reporting_type_1"), 1],
                           [t("shared.advanced_search.reporting_type_2"), 2],
                           [t("shared.advanced_search.reporting_type_3"), 3],
                           [t("shared.advanced_search.reporting_type_4"), 4],
                           [t("shared.advanced_search.reporting_type_5"), 5],
                           [t("shared.advanced_search.reporting_type_6"), 6],
                           [t("shared.advanced_search.reporting_type_7"), 7],
                           [t("shared.advanced_search.reporting_type_8"), 8],
                           [t("shared.advanced_search.reporting_type_9"), 9],
                           [t("shared.advanced_search.reporting_type_10"), 10],
                           [t("shared.advanced_search.reporting_type_11"), 11],
                           [t("shared.advanced_search.reporting_type_12"), 12],
                           [t("shared.advanced_search.reporting_type_13"), 13],
                           [t("shared.advanced_search.reporting_type_14"), 14],
                           [t("shared.advanced_search.reporting_type_15"), 15],
                           [t("shared.advanced_search.reporting_type_16"), 16]],
                       selected_reporting_type_range)
  end

  #per sector
  def sector_options
    options_for_select([
                           [t("shared.advanced_search.sector_name"), 1]], selected_sector_range)
  end

  #per sector_type
  def sector_type_options
    options_for_select([
                           [t("shared.advanced_search.sector_type_1"), 1],
                           [t("shared.advanced_search.sector_type_2"), 2],
                           [t("shared.advanced_search.sector_type_3"), 3],
                           [t("shared.advanced_search.sector_type_4"), 4],
                           [t("shared.advanced_search.sector_type_5"), 5],
                           [t("shared.advanced_search.sector_type_6"), 6]],
                       selected_sector_type_range)
  end

  # per sector
  def selected_sector_range
    params[:advanced_search].try(:[], :name)
  end

  def event_types_all
    event_types_name = Array.new
    event_types = EventType.all
    event_types.each do |type|
      event_types_name.push([type.event_category, type.id])
    end
    options_for_select(event_types_name, selected_event_type_range)
  end

  #institution
  def institution_types_all
    institution_types_name = Array.new
    institution_types = Institution.all
    institution_types.each do |type|
      institution_types_name.push([type.name, type.id])
    end
    options_for_select(institution_types_name, selected_institution_types_range)
  end

  # per institution_types
  def selected_institution_types_range
    params[:advanced_search].try(:[], :institution_id)
  end

  # per event
  def selected_event_type_range
    params[:advanced_search].try(:[], :event_type)
  end

  #-------- Selected value logic ------------

  # per reporting
  def selected_reporting_type_range
    params[:advanced_search].try(:[], :reporting_type)
  end


  def selected_sector_type_range
    if params[:sector_type].present?
      params[:sector_type]
    else
      params[:advanced_search].try(:[], :sector_type)
    end
  end


  def selected_date_range
    custom_date_range? ? 'custom' : params[:advanced_search].try(:[], :date_period)
  end

  def selected_event_date_range
    custom_event_date_range? ? 'custom' : params[:advanced_search].try(:[], :period_event)
  end

  def custom_date_range?
    params[:advanced_search].try(:[], :date_max).present?
  end

  def custom_event_date_range?
    params[:advanced_search].try(:[], :date_min_event).present?
  end

  def hash_is_empty?(hash)
    unless hash.present?
      return true
    end

    hash.values.each do |value|
      unless value.blank?
        return false
      end
    end

    true
  end

end
