class AddEventsToMapLocation < ActiveRecord::Migration
  def change
    add_reference :map_locations, :event, index: true, foreign_key: true, null: true
  end
end
