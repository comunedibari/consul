class AddTimestampsToSector < ActiveRecord::Migration
  def change
    add_timestamps :sectors, null: true
  end
end
