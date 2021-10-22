class CreateSector < ActiveRecord::Migration
  def change
    create_table :sectors do |t|
      t.string  "name"
      t.string  "vat_code"
      t.string  "address"
      t.string  "legal_representative"
      t.string  "phone_number"
      t.string  "email"
      t.references :sector_type, index: true, foreign_key: true, null:false
    end
  end
end
