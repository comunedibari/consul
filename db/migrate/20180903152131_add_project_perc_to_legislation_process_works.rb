class AddProjectPercToLegislationProcessWorks < ActiveRecord::Migration
  def change
    add_column :legislation_process_works, :project_perc, :integer
  end
end
