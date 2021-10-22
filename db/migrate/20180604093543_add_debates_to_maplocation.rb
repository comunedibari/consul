class AddDebatesToMaplocation < ActiveRecord::Migration
  def change
    add_column :map_locations, :debate_id, :integer
    add_index :map_locations, :debate_id
  end
end
