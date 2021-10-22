class ChangeTypeOfValueInvestmentInUserInvestments < ActiveRecord::Migration
  def up
    change_column :user_investments, :value_investements, :float
  end

  def down
    change_column :user_investments, :value_investements, :integer
  end

end
