class AddModerationEntityToProposals < ActiveRecord::Migration
  def change
    add_column :proposals, :moderation_entity, :integer, null: true
  end
end
