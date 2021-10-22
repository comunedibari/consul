class AddNewColumsToSectors < ActiveRecord::Migration
  def up
    add_column :sectors, :description, :string, default: ''
  end

  def down
    remove_column :sectors, :description
  end
end
