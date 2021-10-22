class AddSubscriptionsCountToCollaborationAgreements < ActiveRecord::Migration
  def change
    add_column :collaboration_agreements, :subscriptions_count, :integer
  end
end
