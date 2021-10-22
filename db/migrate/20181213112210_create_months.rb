class CreateMonths < ActiveRecord::Migration
  def change
    create_table :months do |t|
      t.belongs_to :availability, index: true, foreign_key: true
      t.integer :month
      t.boolean :checked, default: false
      t.timestamps null: false
    end
  end
end
