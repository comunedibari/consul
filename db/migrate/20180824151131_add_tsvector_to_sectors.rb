class AddTsvectorToSectors < ActiveRecord::Migration
  def change
    add_column :sectors, :tsv, :tsvector
    add_index :sectors, :tsv, using: "gin"
  end
end
