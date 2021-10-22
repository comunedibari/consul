class RemovePonidFromTags < ActiveRecord::Migration
  def up
    remove_index :tags, column: [:pon_id]
    #remove_index :tags, column: [:pon_id, :name]
    remove_foreign_key :tags, column: "pon_id"
    remove_column :tags, :pon_id
  end

  def down 
    add_reference :tags, :pon, index: true, foreign_key: true, null:false,default: 0
  end

end