class CreatePons < ActiveRecord::Migration
  def change
    create_table :pons do |t|
      t.string :name
      t.string :external_code
      t.string :census_code

    end
    add_index :pons, :id
  end
end
