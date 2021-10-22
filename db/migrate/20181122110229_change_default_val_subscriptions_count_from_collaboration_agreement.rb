class ChangeDefaultValSubscriptionsCountFromCollaborationAgreement < ActiveRecord::Migration
  def up
    Collaboration::Agreement.where("subscriptions_count is null").update_all ["subscriptions_count = ?", 0]
    change_column :collaboration_agreements, :subscriptions_count, :integer, null: false, :default => 0
  end

  def down
    change_column :collaboration_agreements, :subscriptions_count, :integer, null: true
    change_column_default(:collaboration_agreements, :subscriptions_count, nil)
  end
end
