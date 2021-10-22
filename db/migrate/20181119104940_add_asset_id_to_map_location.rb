class AddAssetIdToMapLocation < ActiveRecord::Migration
  def change
    add_column :map_locations, :asset_id, :integer
  end
end
