class AddReportingRefToMapLocations < ActiveRecord::Migration
  def change
    add_reference :map_locations, :reporting, index: true, foreign_key: true, null: true
  end
end
