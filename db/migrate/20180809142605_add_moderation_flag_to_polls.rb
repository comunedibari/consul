class AddModerationFlagToPolls < ActiveRecord::Migration
  def change
    add_column :polls, :moderation_flag, :boolean, null: true
  end
end
