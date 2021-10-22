class AddProcessesToMaplocation < ActiveRecord::Migration
  def change
    add_column :map_locations, :process_id, :integer
    add_index :map_locations, :process_id
  end
end
