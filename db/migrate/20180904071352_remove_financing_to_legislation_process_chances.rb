class RemoveFinancingToLegislationProcessChances < ActiveRecord::Migration
  def change
    remove_column :legislation_process_chances, :financing, :string
  end
end
