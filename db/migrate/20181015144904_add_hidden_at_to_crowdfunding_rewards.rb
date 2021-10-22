class AddHiddenAtToCrowdfundingRewards < ActiveRecord::Migration
  def change
    add_column :crowdfunding_rewards, :hidden_at, :datetime
    add_index :crowdfunding_rewards, :hidden_at
  end
end
