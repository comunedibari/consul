class AddFiscalDataToUserInvestments < ActiveRecord::Migration
  def change
    add_column :user_investments, :fiscal_data, :text
    add_index :user_investments, :fiscal_data
  end
end
