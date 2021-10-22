class AddTypeToLegislationProcesses < ActiveRecord::Migration
  def change
    add_column :legislation_processes, :process_type, :integer, default: 1
  end
end
