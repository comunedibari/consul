class AddPonRefToSiteCustomizationImages < ActiveRecord::Migration
  def change
    add_reference :site_customization_images, :pon, index: true, foreign_key: true, null: false
  end
end
