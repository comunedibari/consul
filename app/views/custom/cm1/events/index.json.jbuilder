json.array! (@event_slots) do |slot|
    date_format_all_day = '%Y-%m-%d'
    date_format = '%Y-%m-%dT%H:%M:%S'
    date_format = slot.event.all_day_event? ? date_format_all_day : date_format
    link = event_path(slot.event)
    if slot.event.event_type.creable > 0
      eventable = EventContent.where(event_id: slot.event_id).first.eventable
      link = url_for(eventable)
    end
    json.id slot.id
    json.event_id slot.event_id
    json.title slot.event.title
    json.start slot.start_event.strftime(date_format)
    json.end slot.end_event.strftime(date_format)
    json.color slot.event.event_type.event_color
    json.allDay slot.event.all_day_event? ? true : false
    json.link link
  end