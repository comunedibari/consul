class AddUserIdToCrowdfundingRewards < ActiveRecord::Migration
  def change
    add_column :crowdfunding_rewards, :author_id, :integer
  end
end
