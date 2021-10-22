class CreateEventNotifications < ActiveRecord::Migration
  def change
    create_table :event_notifications do |t|
      t.string :title
      t.text :body
      t.integer :author_id
      t.integer :event_id
      t.timestamps null: false
    end
  end
end
