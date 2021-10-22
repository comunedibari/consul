class AddVisibleToLegislationProcess < ActiveRecord::Migration
  def up
    add_column :legislation_processes, :visible, :boolean
  end

  def down
    remove_column :legislation_processes, :visible
  end
end
