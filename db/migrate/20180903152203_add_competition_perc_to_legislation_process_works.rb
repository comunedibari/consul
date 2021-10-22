class AddCompetitionPercToLegislationProcessWorks < ActiveRecord::Migration
  def change
    add_column :legislation_process_works, :competition_perc, :integer
  end
end
