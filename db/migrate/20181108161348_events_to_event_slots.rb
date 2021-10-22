class EventsToEventSlots < ActiveRecord::Migration
  def change
    add_reference :event_slots, :events, index: true, foreign_key: true
  end
end
