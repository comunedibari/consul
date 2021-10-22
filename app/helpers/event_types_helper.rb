module EventTypesHelper

    def event_types_select_options
        EventType.where(creable: 0).all.order(event_category: :asc).collect { |t| [ t.event_category, t.id ] }
    end

        
    def event_types_image_url (type_name)
        image_url= "/assets/event_types/#{type_name}.png"
    end

    def events_by_event_type_id(event_type_id)
        events = Sector.where("event_type_id = ?", event_type_id)
        events.count
        
    end

end
