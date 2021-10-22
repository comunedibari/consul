class AddCrowdfundingsCountToTags < ActiveRecord::Migration
  def change
    add_column :tags, :crowdfundings_count, :integer, default: 0
    add_index :tags, :crowdfundings_count
  end
end
