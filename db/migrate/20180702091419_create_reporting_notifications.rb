class CreateReportingNotifications < ActiveRecord::Migration
  def change
    create_table :reporting_notifications do |t|
      t.string :title
      t.text :body
      t.integer :author_id
      t.integer :reporting_id
      t.timestamps null: false

    end
  end
end
