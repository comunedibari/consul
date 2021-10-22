class AddLegislationProcessTypologyForeignKeyToLegislationProcesses < ActiveRecord::Migration
  def up
    add_column :legislation_processes, :legislation_process_typologies_id, :integer, default: 1
  end

  def down
    remove_column :legislation_processes, :legislation_process_typologies_id
  end
end
