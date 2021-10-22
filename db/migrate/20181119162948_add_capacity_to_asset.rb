class AddCapacityToAsset < ActiveRecord::Migration
  def change
    add_column :assets, :capacity, :integer
  end
end
