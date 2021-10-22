class AddModerationEntityToEvents < ActiveRecord::Migration
  def change
    add_column :events, :moderation_entity, :integer, null: true

  end
end
