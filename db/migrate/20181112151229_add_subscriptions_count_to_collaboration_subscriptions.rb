class AddSubscriptionsCountToCollaborationSubscriptions < ActiveRecord::Migration
  def change
    add_column :collaboration_subscriptions, :subscriptions_count, :integer
  end
end
