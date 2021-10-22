class AddPonRefToBudgetInvestments < ActiveRecord::Migration
  def change
    add_reference :budget_investments, :pon, index: true, foreign_key: true, null: false
  end
end
