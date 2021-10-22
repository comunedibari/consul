class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.string "name"
      t.string "description"
      t.string "address"
      t.string "contacts"
      t.timestamps null: false
      t.datetime "hidden_at"
    end
  end
end
