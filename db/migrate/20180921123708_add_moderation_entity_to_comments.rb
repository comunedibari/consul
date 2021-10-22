class AddModerationEntityToComments < ActiveRecord::Migration
  def change
    add_column :comments, :moderation_entity, :integer, null: true
  end
end
