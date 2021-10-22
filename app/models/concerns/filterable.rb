module Filterable
  extend ActiveSupport::Concern

  included do
    scope :by_official_level, ->(official_level) { where(users: { official_level: official_level }).joins(:author) }
    scope :by_date_range,     ->(date_range)     { where(created_at: date_range) }

    #scope :by_start_event,     ->(start_event)     { where(start_event: start_event) } #old

    #scope :by_event_date,     ->(event_date)     { where('start_event < ?', event_date).where('end_event > ?',event_date) }
    #scope :by_start_event,     ->(start_event)     { where.any_of(by_event_date(start_event[1]),by_event_date(start_event[2]),start_event: start_event[0], end_event: start_event[0]) }

    scope :by_start_event,     ->(start_event)     { where(id: EventSlot.by_filter_date(start_event)) }

    scope :by_reporting_type,   ->(reporting_type_id)     { where(reporting_type_id: reporting_type_id) }
    scope :by_sector_type,     ->(sector_type_id)     { where(sector_type_id: sector_type_id) }
    scope :by_event_type,     ->(event_type_id)     { where(event_type_id: event_type_id) }
    scope :by_institution_id,     ->(institution_id)     { joins(:reporting_type).where("reporting_types.institution_id = ?",institution_id) }
  end

  class_methods do

    def filter(params)
      resources = all
      params.each do |filter, value|
        if allowed_filter?(filter, value)
          resources = resources.send("by_#{filter}", value)
        end
      end
      resources
    end

    def allowed_filter?(filter, value)
      return if value.blank?
      ['official_level', 'date_range','reporting_type','sector_type','event_type','start_event','event_dateq', 'institution_id', 'typology_id'].include?(filter)
    end

  end

end
