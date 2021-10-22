class RemovePriceToLegislationProcessChances < ActiveRecord::Migration
  def change
    remove_column :legislation_process_chances, :price, :string
  end
end
