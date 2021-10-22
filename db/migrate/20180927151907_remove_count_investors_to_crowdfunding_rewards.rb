class RemoveCountInvestorsToCrowdfundingRewards < ActiveRecord::Migration
  def up
    remove_column :crowdfunding_rewards, :count_investors
  end
end
