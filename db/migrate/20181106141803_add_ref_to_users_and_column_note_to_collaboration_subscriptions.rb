class AddRefToUsersAndColumnNoteToCollaborationSubscriptions < ActiveRecord::Migration
  def change
    add_reference :collaboration_subscriptions, :user, index: true, foreign_key: true, null: true
    add_column :collaboration_subscriptions, :note, :text
  end
end
