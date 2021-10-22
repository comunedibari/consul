class AddPonRefToBanners < ActiveRecord::Migration
  def change
    add_reference :banners, :pon, index: true, foreign_key: true, null:false
  end
end
