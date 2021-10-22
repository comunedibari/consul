module EventsSlotsHelper
  
  def event_slots_note(event,max_d=nil)
    t "events.slots.form.note", max_slots_allowed: max_d
  end


  def max_slots_allowed?(event)
    event.event_slots.count >= event.max_slots
  end

  def max_slot(event)
    event.max_slots
  end

  def render_destroy_slot_link(builder, slot)
    link_to_remove_association slot.new_record? ? t('events.slots.form.cancel_button') : t('events.slots.form.delete_button') , builder, class: "delete remove-slot"
  end

  def format_date_for_calendar_form(date)
    l(date, format: "%d/%m/%Y") if date # %hh:%mm
  end

end
