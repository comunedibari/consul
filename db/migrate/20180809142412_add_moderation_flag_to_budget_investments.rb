class AddModerationFlagToBudgetInvestments < ActiveRecord::Migration
  def change
    add_column :budget_investments, :moderation_flag, :boolean, null: true
  end
end
