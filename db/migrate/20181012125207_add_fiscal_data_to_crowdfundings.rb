class AddFiscalDataToCrowdfundings < ActiveRecord::Migration
  def change
    add_column :crowdfundings, :fiscal_data, :text
    add_index :crowdfundings, :fiscal_data
  end
end
