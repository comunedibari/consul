class CreateYears < ActiveRecord::Migration
  def change
    create_table :years do |t|
      t.belongs_to :availability, index: true, foreign_key: true
      t.integer :year
      t.column :hidden_at, :datetime
      t.timestamps null: false
    end
  end
end
