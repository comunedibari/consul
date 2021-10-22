class AddModerationEntityToDebates < ActiveRecord::Migration
  def change
    add_column :debates, :moderation_entity, :integer, null: true
  end
end
