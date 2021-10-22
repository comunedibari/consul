class AddEventsNewToMaplocation < ActiveRecord::Migration
  def change
    remove_column :map_locations, :event_id
    add_reference :map_locations, :event, index: true, foreign_key: true, null: true
  end
end
