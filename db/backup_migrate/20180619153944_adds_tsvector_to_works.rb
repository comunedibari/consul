class AddsTsvectorToReportings < ActiveRecord::Migration
  
  def up
    add_column :reportings, :tsv, :tsvector
    add_index :reportings, :tsv, using: "gin"
  end
    
  def down
    remove_index :reportings, :tsv
    remove_column :reportings, :tsv
  end
end
