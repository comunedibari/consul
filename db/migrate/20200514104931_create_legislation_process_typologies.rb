class CreateLegislationProcessTypologies < ActiveRecord::Migration
  def change
    create_table :legislation_process_typologies do |t|
      t.string :name
      t.datetime :hidden_at
      t.boolean :active
    end
  end
end
