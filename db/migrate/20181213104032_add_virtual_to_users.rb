class AddVirtualToUsers < ActiveRecord::Migration
  def change
    add_column :users, :virtual, :boolean
  end
end
