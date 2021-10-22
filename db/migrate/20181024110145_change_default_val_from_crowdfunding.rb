class ChangeDefaultValFromCrowdfunding < ActiveRecord::Migration
  def up
    change_column :crowdfundings, :total_investiment, :float, null: true, :default => 0
    change_column :crowdfundings, :count_investors, :integer, null: true, :default => 0
    Crowdfunding.where("total_investiment is null").update_all ["total_investiment = ?", 0]
    Crowdfunding.where("count_investors is null").update_all ["count_investors = ?", 0]
  end

  def down
    change_column :crowdfundings, :total_investiment, :float, null: true
    change_column_default(:crowdfundings, :total_investiment, nil)
    change_column :crowdfundings, :count_investors, :integer, null: true
    change_column_default(:crowdfundings, :count_investors, nil)
  end
end
