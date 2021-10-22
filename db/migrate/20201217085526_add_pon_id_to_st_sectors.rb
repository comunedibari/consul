class AddPonIdToStSectors < ActiveRecord::Migration
  def up
    add_column :st_sectors, :pon_id, :integer
    add_column :st_sectors, :description, :string, default: ''
    add_column :st_sectors, :sector_id, :integer
    add_column :st_sectors, :cf_rappr_legale, :string, default: ''
    add_column :st_sectors, :tsv, :tsvector
    add_index :st_sectors, :tsv, using: "gin"
    add_column :st_sectors, :user_id, :integer
    add_column :st_sectors, :created_at, :datetime
    add_column :st_sectors, :updated_at, :datetime
    add_column :st_sectors, :status_edit, :integer
  end

  def down
    remove_column :st_sectors, :pon_id
    remove_column :st_sectors, :description
    remove_column :st_sectors, :sector_id
    remove_column :st_sectors, :cf_rappr_legale
    remove_index :st_sectors, :tsv
    remove_column :st_sectors, :tsv
    remove_column :st_sectors, :user_id
    remove_column :st_sectors, :created_at
    remove_column :st_sectors, :updated_at
    remove_column :st_sectors, :status_edit
  end
end
