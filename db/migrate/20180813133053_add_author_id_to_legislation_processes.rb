class AddAuthorIdToLegislationProcesses < ActiveRecord::Migration
  def change
    add_column :legislation_processes, :author_id, :integer
  end
end
