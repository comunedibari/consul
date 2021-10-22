class AddNewColumsToUserInvestments < ActiveRecord::Migration
  def up
    add_column :user_investments, :investor, :string, default: ''
    add_column :user_investments, :email, :string, default: ''
    add_column :user_investments, :fiscal_code, :string, limit: 16
    add_column :user_investments, :payment_id, :string, default: ''
  end

  def down
    remove_column :user_investments, :investor
    remove_column :user_investments, :email
    remove_column :user_investments, :fiscal_code
    remove_column :user_investments, :payment_id
  end
end
