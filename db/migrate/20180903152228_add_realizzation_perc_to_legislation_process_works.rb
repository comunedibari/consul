class AddRealizzationPercToLegislationProcessWorks < ActiveRecord::Migration
  def change
    add_column :legislation_process_works, :realizzation_perc, :integer
  end
end
