class AddStatusToUserInvestments < ActiveRecord::Migration
  def change
    add_column :user_investments, :status, :string
  end
end
