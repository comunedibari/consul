class AddModerationEntityToLegislationProposals < ActiveRecord::Migration
  def change
    add_column :legislation_proposals, :moderation_entity, :integer, null: true
  end
end
