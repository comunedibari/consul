class AddSectorsToMaplocation < ActiveRecord::Migration
  def change
    add_reference :map_locations, :sector, index: true, foreign_key: true, null: true

  end
end
