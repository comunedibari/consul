class AddEventsNewCountToTags < ActiveRecord::Migration
  def change
    add_column :tags, :events_count,  :integer, default: 0
  end
end
