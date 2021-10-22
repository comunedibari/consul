class AddPonToAssets < ActiveRecord::Migration
  
  def up
    add_reference :assets, :pon, index: true, foreign_key: true, null:false,default: 0
    Asset.where("pon_id is null").update_all ["pon_id = ?", 0]
    change_column :assets, :pon_id, :integer, null: false, :default => 0
  end

  def down
    remove_foreign_key :assets, column: "pon_id"
    remove_column :assets, :pon_id
  end

end
