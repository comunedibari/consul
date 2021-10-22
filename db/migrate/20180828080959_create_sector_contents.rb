class CreateSectorContents < ActiveRecord::Migration
  def change
    create_table :sector_contents do |t|
      t.references :sectorable, polymorphic: true, index: true
    end
    add_index :sector_contents, [ :sectorable_type, :sectorable_id], name: "access_sector_contents"
  end

end
