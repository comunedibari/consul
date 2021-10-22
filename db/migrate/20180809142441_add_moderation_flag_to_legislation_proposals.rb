class AddModerationFlagToLegislationProposals < ActiveRecord::Migration
  def change
    add_column :legislation_proposals, :moderation_flag, :boolean, null: true
  end
end
