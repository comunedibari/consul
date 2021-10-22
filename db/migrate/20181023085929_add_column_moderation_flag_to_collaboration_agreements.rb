class AddColumnModerationFlagToCollaborationAgreements < ActiveRecord::Migration
  def change
    add_column :collaboration_agreements, :moderation_flag, :boolean, null: true
  end
end
