module Search
  extend ActiveSupport::Concern

  included do
    before_action :parse_search_terms, only: [:index, :suggest]
    before_action :parse_advanced_search_terms, only: :index
    before_action :parse_process_typology_id_array, only: :index
    before_action :set_search_order, only: :index
  end

  def parse_search_terms
    @search_terms = params[:search] if params[:search].present?
    #logger.debug "++++++++++++ search_terms(normale)=  "+@search_terms.to_s
  end

  def parse_advanced_search_terms
    @advanced_search_terms = params[:advanced_search] if params[:advanced_search].present?
    parse_search_date
    parse_event_search_date
  end

  def parse_event_search_date
    return unless search_event_by_date?
    #params[:advanced_search][:start_event] = search_event_date_range
    date_arr = [search_event_date_range, format_event_start_date, format_event_finish_date]
    params[:advanced_search][:start_event] = date_arr
  end

  def parse_search_date
    return unless search_by_date?
    params[:advanced_search][:date_range] = search_date_range
  end

  def parse_process_typology_id_array
    return unless search_by_category?
    @typology_ids_array = params[:typology][:id].split(",")
  end

  def search_by_category?
    # params[:advanced_search] && (params[:typology].present? && params[:typology][:id].present?)
    params[:typology].present? && params[:typology][:id].present?
  end

  def search_by_date?
    params[:advanced_search] && (params[:advanced_search][:date_period].present? || params[:advanced_search][:date_min].present?)
  end

  def search_event_by_date?
    params[:advanced_search] && (params[:advanced_search][:period_event].present? || params[:advanced_search][:date_min_event].present?)
  end

  def search_start_date
    case params[:advanced_search][:date_period]
    when '1'
      24.hours.ago
    when '2'
      1.week.ago
    when '3'
      1.month.ago
    when '4'
      1.year.ago
    else
      Date.parse(params[:advanced_search][:date_min]) rescue 100.years.ago
    end
  end

  def search_event_start_date
    case params[:advanced_search][:period_event]
    when '10' #oggi
      0.hours.from_now
    when '11' # domani
      24.hours.from_now
    when '12' # settimana corrente
      0.hours.from_now
    when '13' # mese corrente
      0.hours.from_now
    else
      Date.parse(params[:advanced_search][:date_min_event]) # rescue 100.years.ago
    end
  end

  def format_event_start_date
    case params[:advanced_search][:period_event]
    when '10' #oggi
      0.hours.from_now.strftime("%d-%m-%Y")
    when '11' # domani
      24.hours.from_now.strftime("%d-%m-%Y")
    when '12' # settimana corrente
      0.hours.from_now.strftime("%d-%m-%Y")
    when '13' # mese corrente
      0.hours.from_now.strftime("%d-%m-%Y")
    else
      params[:advanced_search][:date_min_event]
    end
  end

  def search_finish_date
    (params[:advanced_search][:date_max].to_date rescue Date.current) || Date.current
  end

  def search_event_finish_date
    #(params[:advanced_search][:date_max_event].to_date rescue Date.current) || Date.current
    case params[:advanced_search][:period_event]
    when '10' #oggi
      0.hours.from_now
    when '11' # domani
      24.hours.from_now
    when '12' # settimana corrente
      Date.current.end_of_week
    when '13' # mese corrente
      0.hours.from_now.end_of_month
    else
      Date.parse(params[:advanced_search][:date_max_event]) #rescue 100.years.ago
    end
  end

  def format_event_finish_date
    #(params[:advanced_search][:date_max_event].to_date rescue Date.current) || Date.current
    case params[:advanced_search][:period_event]
    when '10' #oggi
      0.hours.from_now.strftime("%d-%m-%Y")
    when '11' # domani
      24.hours.from_now.strftime("%d-%m-%Y")
    when '12' # settimana corrente
      Date.current.end_of_week.strftime("%d-%m-%Y")
    when '13' # mese corrente
      0.hours.from_now.end_of_month.strftime("%d-%m-%Y")
    else
      params[:advanced_search][:date_max_event]
    end

  end

  def search_date_range
    [100.years.ago, search_start_date].max.beginning_of_day..[search_finish_date, Date.current].min.end_of_day
  end

  def search_event_date_range
    #[100.years.ago, search_event_start_date].max.beginning_of_day..[search_event_finish_date, Date.current].min.end_of_day
    [100.years.ago, search_event_start_date].max.beginning_of_day..search_event_finish_date.end_of_day
  end


  def set_search_order
    if params[:search].present? && params[:order].blank?
      params[:order] = 'relevance'
    end
  end

end
