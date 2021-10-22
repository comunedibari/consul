class RemoveFiscalDataFromUserInvestments < ActiveRecord::Migration
  def change
    remove_column :user_investments, :fiscal_data, :text
  end
end
