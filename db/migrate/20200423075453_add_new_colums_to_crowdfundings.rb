class AddNewColumsToCrowdfundings < ActiveRecord::Migration
  def up
    add_column :crowdfundings, :flag_rewards, :boolean, default: false
    add_column :crowdfundings, :flag_refund, :boolean, default: false
    add_column :crowdfundings, :flag_investments, :boolean, default: true
  end

  def down
    remove_column :crowdfundings, :flag_rewards
    remove_column :crowdfundings, :flag_refund
    remove_column :crowdfundings, :flag_investments
  end
end
