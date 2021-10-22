class AddCrowdfundingsToMapLocation < ActiveRecord::Migration
    def change
      add_reference :map_locations, :crowdfunding, index: true, foreign_key: true, null: true

    end
end
