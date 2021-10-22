class AddUsersToMaplocation < ActiveRecord::Migration
  def change
    add_column :map_locations, :user_id, :integer
    add_index :map_locations, :user_id
  end
end
