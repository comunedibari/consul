class AddFinancingPercToLegislationProcessWorks < ActiveRecord::Migration
  def change
    add_column :legislation_process_works, :financing_perc, :integer
  end
end
