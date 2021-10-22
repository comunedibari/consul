class CreateCrowdfundingNotifications < ActiveRecord::Migration
  def change
    create_table :crowdfunding_notifications do |t|
      t.string :title
      t.text :body
      t.integer :author_id
      t.integer :crowdfunding_id

      t.timestamps null: false
    end
  end
end
