class AddHiddenAtToUserInvestments < ActiveRecord::Migration
  def change
    add_column :user_investments, :hidden_at, :datetime
    add_index :user_investments, :hidden_at
  end
end
