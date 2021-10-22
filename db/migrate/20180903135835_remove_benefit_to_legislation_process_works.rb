class RemoveBenefitToLegislationProcessWorks < ActiveRecord::Migration
  def change
    remove_column :legislation_process_works, :benefit, :string
  end
end
