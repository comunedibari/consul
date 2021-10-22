class AlterReportingsTable < ActiveRecord::Migration
  
  def up
    change_column :reportings, :title, :string, limit: 255
    change_column :reportings, :address, :string, limit: 255
    change_column :reportings, :responsible_name, :string, limit: 255
  end

  def down
    change_column :reportings, :title, :string, limit: 80
    change_column :reportings, :address, :string, limit: 80
    change_column :reportings, :responsible_name, :string, limit: 80
  end

end
