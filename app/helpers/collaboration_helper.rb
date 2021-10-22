module CollaborationHelper
  def format_date(date)
    l(date, format: "%d/%m/%Y") if date
  end

  def format_date_for_calendar_form(date)
    l(date, format: "%d/%m/%Y") if date
  end

  def status_select_options_subscriptions
    Collaboration::Subscription::STATUS_OPTIONS_SUBSCRIPTIONS.collect { |option| [ "#{option}", option ] }
  end

  def collaboration_agreement_finances_by_agreement(agreement)
      @collaboration_agreement_finances = Collaboration::ProcessFinance.all.where(collaboration_agreement_id: @agreement.id )      
  end

  def collaboration_agreement_phases_by_agreement(agreement)
    @collaboration_agreement_phases = Collaboration::ProcessPhase.all.where(collaboration_agreement_id: @agreement.id)      
  end

  def requirements_by_agreement(agreement) 
    requirements_names = Array.new
    requirements = Collaboration::AgreementRequirement.all.where(collaboration_agreement_id: agreement.id )
    requirements.each do |reqirement|
      requirements_names.push(reqirement.title )
    end
    requirements_names.push("ALTRO")
    requirements_names
  end

end
