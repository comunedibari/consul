class AddAssetsCountToTag < ActiveRecord::Migration
  def change
    add_column :tags, :assets_count,  :integer, default: 0
  end
end