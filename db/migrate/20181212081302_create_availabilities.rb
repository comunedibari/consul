class CreateAvailabilities < ActiveRecord::Migration
  def change
    create_table :availabilities do |t|
      t.references :asset, index: true, foreign_key: true
      t.column :hidden_at, :datetime
      t.timestamps null: false
    end

  end

end
