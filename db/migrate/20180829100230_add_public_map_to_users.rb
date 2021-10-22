class AddPublicMapToUsers < ActiveRecord::Migration
  def change
    add_column :users, :public_map, :boolean, default: true
  end
end
