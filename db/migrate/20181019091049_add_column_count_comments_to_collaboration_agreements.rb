class AddColumnCountCommentsToCollaborationAgreements < ActiveRecord::Migration
  def change
    add_column :collaboration_agreements, :comments_count, :integer, default: 0
  end
end
