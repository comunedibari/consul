class AddExternalIdToLegislationProcesses < ActiveRecord::Migration
  def change
    add_column :legislation_processes, :external_id, :integer, null: true
  end
end
