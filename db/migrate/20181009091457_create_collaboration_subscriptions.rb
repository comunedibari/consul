class CreateCollaborationSubscriptions < ActiveRecord::Migration
  def change
    create_table :collaboration_subscriptions do |t|
      t.belongs_to :collaboration_agreement, index: true, foreign_key: true
      t.bigint :price
      t.string :financing
      t.string :work_status
      t.string :address
      t.string :contacts
      t.string :external_url
      t.integer :project_perc
      t.integer :financing_perc
      t.integer :competition_perc
      t.integer :realizzation_perc
    end
  end
end
