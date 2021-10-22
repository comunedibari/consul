module LegislationHelper
  def format_date(date)
    l(date, format: "%d/%m/%Y") if date
  end

  def format_date_for_calendar_form(date)
    l(date, format: "%d/%m/%Y") if date
  end

  def status_select_options_works
    Legislation::ProcessWork::STATUS_OPTIONS_WORKS.collect { |option| ["#{option}", option] }
  end

  def legislation_process_finances_by_process(process)
    @legislation_process_finances = Legislation::ProcessFinance.all.where(legislation_process_id: @process.id)
  end

  def legislation_process_phases_by_process(process)
    @legislation_process_phases = Legislation::ProcessPhase.all.where(legislation_process_id: @process.id)
  end

  def get_typologies
    tipologies = ::Legislation::ProcessTypology.all
    typologies_array = []

    tipologies.each do |typology|
      typologies_array.push([typology.name, typology.id])
    end

    typologies_array
  end

  def get_typology_name_by_id typology_id
    ::Legislation::ProcessTypology.all.where(id: typology_id).first.name
  end

  def get_typology_class_by_id typology_id
    case typology_id
    when 1
      return 'secondary'
    when 2
      return 'primary'
    when 3
      return 'warning'
    else
      return 'secondary'
    end
  end

end
