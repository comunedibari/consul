class CreateDays < ActiveRecord::Migration
  def change
    create_table :days do |t|
      t.belongs_to :availability, index: true, foreign_key: true
      t.integer :day
      t.column :am_start, :time
      t.column :am_end, :time
      t.column :pm_start, :time
      t.column :pm_end, :time
      t.column :hidden_at, :datetime
      t.timestamps null: false
    end
  end
end
