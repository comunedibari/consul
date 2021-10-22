class AddPonRefToSiteCustomizationContentBlocks < ActiveRecord::Migration
  def change
    add_reference :site_customization_content_blocks, :pon, index: true, foreign_key: true, null: false
  end
end
