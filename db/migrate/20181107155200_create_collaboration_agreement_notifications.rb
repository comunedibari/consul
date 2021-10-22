class CreateCollaborationAgreementNotifications < ActiveRecord::Migration
  def change
    create_table :collaboration_agreement_notifications do |t|
      t.string :title
      t.text :body
      t.integer :author_id
      t.integer :collaboration_agreement_id
      t.timestamps null: false
    end
  end
end
