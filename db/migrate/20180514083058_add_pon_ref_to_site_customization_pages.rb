class AddPonRefToSiteCustomizationPages < ActiveRecord::Migration
  def change
    add_reference :site_customization_pages, :pon, index: true, foreign_key: true, null: false
  end
end
