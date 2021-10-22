class MakeMapLocationPolymorphic < ActiveRecord::Migration
  def change
    drop_table :map_locations

    create_table :map_locations do |t|
      t.references :localizable, polymorphic: true, index: true
      t.float :latitude
      t.float :longitude
      t.integer :zoom
      t.timestamps
    end
  end
end
