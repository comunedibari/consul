class AddColumnsToUserInvestments < ActiveRecord::Migration
  def up
    add_column :user_investments, :credit_id, :string, default: ''
    add_column :user_investments, :visible, :boolean, default: false
  end

  def down
    remove_column :user_investments, :credit_id
    remove_column :user_investments, :visible
  end
end
