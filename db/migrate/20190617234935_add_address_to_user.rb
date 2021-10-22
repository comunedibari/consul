class AddAddressToUser < ActiveRecord::Migration
  def up
    add_column :users, :address,  :string, default: ''
  end

  def down
    remove_column :users, :address
  end
end
