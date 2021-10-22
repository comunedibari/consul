class AddModerationFlagtoProposals < ActiveRecord::Migration
  def change
    add_column :proposals, :moderation_flag, :boolean, null: true
  end
end
