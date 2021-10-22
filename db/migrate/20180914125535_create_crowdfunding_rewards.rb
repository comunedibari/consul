class CreateCrowdfundingRewards < ActiveRecord::Migration
  def change
    create_table :crowdfunding_rewards do |t|

      t.float  "min_investment"
      t.text     "description"
      t.integer  "count_investors"
      t.belongs_to :crowdfunding ,index: true, foreign_key: true

    end
  end
end
