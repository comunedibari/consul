class RemoveFieldsFromCollaborationSubscriptions < ActiveRecord::Migration
  def change
    remove_column :collaboration_subscriptions, :price
    remove_column :collaboration_subscriptions, :financing
    remove_column :collaboration_subscriptions, :work_status
    remove_column :collaboration_subscriptions, :address
    remove_column :collaboration_subscriptions, :contacts
    remove_column :collaboration_subscriptions, :external_url
    remove_column :collaboration_subscriptions, :project_perc
    remove_column :collaboration_subscriptions, :financing_perc
    remove_column :collaboration_subscriptions, :competition_perc
    remove_column :collaboration_subscriptions, :realizzation_perc
  end
end
