class AddInfoRefundAndInfoRewardToUserInvestment < ActiveRecord::Migration

  def change
    add_column :user_investments, :refound_info, :text, null: true
    add_column :user_investments, :reward_info, :text, null: true
  end
end
