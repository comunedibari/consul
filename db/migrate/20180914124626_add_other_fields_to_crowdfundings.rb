class AddOtherFieldsToCrowdfundings < ActiveRecord::Migration
  def change
    add_column :crowdfundings, :price_goal, :float
    add_column :crowdfundings, :min_price, :float
    add_column :crowdfundings, :total_investiment, :float
    add_column :crowdfundings, :count_investors, :integer
    add_column :crowdfundings, :start_date, :datetime
    add_column :crowdfundings, :end_date, :datetime
  end
end
