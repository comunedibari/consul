class CreateGeolocations < ActiveRecord::Migration
  def change
    create_table :geolocations do |t|
      t.references :localizable, polymorphic: true, index: true
      t.decimal :lat 
      t.decimal :lon
      t.integer :srid
      t.timestamps
    end
  end
end
