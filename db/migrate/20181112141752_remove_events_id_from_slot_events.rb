class RemoveEventsIdFromSlotEvents < ActiveRecord::Migration

  def up 
    remove_column :event_slots, :events_id
  end

  def down 
    add_column :event_slots, :events_id, :integer
  end

end
