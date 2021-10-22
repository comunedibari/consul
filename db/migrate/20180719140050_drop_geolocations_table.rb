class DropGeolocationsTable < ActiveRecord::Migration
  def self.up
    drop_table :geolocations
  end

  def self.down
    create_table :geolocations do |t|
      t.references :localizable, polymorphic: true, index: true
      t.decimal :lat 
      t.decimal :lon
      t.integer :srid
      t.timestamps
    end
  end
end
