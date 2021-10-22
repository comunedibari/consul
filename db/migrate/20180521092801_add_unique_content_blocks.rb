class AddUniqueContentBlocks < ActiveRecord::Migration
  def change
    remove_index :site_customization_content_blocks, column:  [:name, :locale, :pon_id], unique: true
  end
  def change
    add_index :site_customization_content_blocks, [:name, :locale, :pon_id], unique: true, :name => "site_customization_name_locale_pon"
  end
  
end
