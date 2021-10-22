class CreateEventSlots < ActiveRecord::Migration
  def change
    create_table :event_slots do |t|
      t.integer :event_id
      t.datetime :start_event
      t.datetime :end_event
    end
  end
end
