class AddPonRefToBudgets < ActiveRecord::Migration
  def change
    add_reference :budgets, :pon, index: true, foreign_key: true, null:false
  end
end
