class AddTsvVectorToAssets < ActiveRecord::Migration
  def up
    add_column :assets, :tsv, :tsvector
    add_column :assets, :author_id, :integer
    #add_column :assets, :hidden_at, :datetime
    add_index :assets, :tsv, using: "gin"
  end

  def down
    remove_index :assets, :tsv
    remove_column :assets, :tsv
    #remove_column :assets, :hidden_at
    remove_column :assets, :author_id
  end
end
