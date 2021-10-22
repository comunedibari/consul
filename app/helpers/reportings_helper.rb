module ReportingsHelper


  def read_only_service
    return false
    if Rails.application.config.cm == 'cm1'
      return true
    else
      return false  
    end  
  end
  
  def new_element_for_service
    if Rails.application.config.cm == 'cm1'
      return true
    else
      return false  
    end  
  end  

  def namespaced_reporting_path(reporting, options = {})
    @namespace_reporting_path ||= namespace
    case @namespace_reporting_path
    when "management"
      management_reporting_path(reporting, options)
    else
      reporting_path(reporting, options)
    end
  end

  def retire_reportings_options
    Reporting::RETIRE_OPTIONS.collect { |option| [ t("proposals.retire_options.#{option}"), option ] }
  end
  
  def empty_recommended_reportings_message_text(user)
    if user.interests.any?
      t('proposals.index.recommendations.without_results')
    else
      t('proposals.index.recommendations.without_interests')
    end
  end

  def author_of_reporting?(reporting)
    author_of?(reporting, current_user)
  end

  def reporting_current_editable?(reporting)
    current_user && reporting.editable_by?(current_user)
  end

  def current_moderable_comments?(reporting)
    current_user && reporting.moderable_comments_by?(current_user)
  end

  def reportings_minimal_view_path
    reportings_path(view: reportings_secondary_view)
  end

  def reportings_default_view?
    @view == "default"
  end

  def reportings_current_view
    @view
  end

  def reportings_secondary_view
    reportings_current_view == "default" ? "minimal" : "default"
  end

    def status_select_options
    Reporting::STATUS_OPTIONS.collect { |option| [ "#{option}", option ] }
  end

  #mia
  def setStyleStatus( string )
    string = string.upcase
    if string.start_with?("CHI")
      "btn-close-status"
    elsif string.start_with?("RIS")
      "btn-resolved-status"      
    elsif string.start_with?("IN COR") or string.start_with?("IN LAV")
      "btn-inProgress-status"
    elsif string.start_with?("APE") or string.start_with?("INOLT")
      "btn-open-status"
    end

  end


  #restituisce arredo-urbano.png
  def reporting_type_verified(url)
    names = url.split('/')
    return  ""+names.last.to_s
  end

  #url è il reporting.reporting_type.url
  def is_image_present(url)
    files =Dir.entries("app/assets/images/custom/reporting_type")
    files.each do |f|
      #logger.debug "    nome_file:      "+ f.to_s
      #logger.debug "url_splittato:      "+ reporting_type_verified(url)

      if reporting_type_verified(url) === f.to_s
        #logger.debug "***********"+ reporting_type_verified(url)
        return true
      end
    end 
    return false 
  end

  def reportings_count
    Reporting.where('moderation_entity is null or moderation_entity = 1').send("sort_by_#{@current_order}").count
  end

end
