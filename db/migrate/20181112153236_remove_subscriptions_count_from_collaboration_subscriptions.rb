class RemoveSubscriptionsCountFromCollaborationSubscriptions < ActiveRecord::Migration
  def change
    remove_column :collaboration_subscriptions, :subscriptions_count
  end
end
