class AddScheduleToAsset < ActiveRecord::Migration
  def change
    add_column :assets, :schedule, :text
  end
end
