class AddModerationFlagtoDebates < ActiveRecord::Migration
  def change
    add_column :debates, :moderation_flag, :boolean, null: true
  end
end
