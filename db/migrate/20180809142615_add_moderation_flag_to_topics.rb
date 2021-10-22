class AddModerationFlagToTopics < ActiveRecord::Migration
  def change
    add_column :topics, :moderation_flag, :boolean, null: true
  end
end
