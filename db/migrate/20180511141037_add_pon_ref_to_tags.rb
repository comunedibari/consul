class AddPonRefToTags < ActiveRecord::Migration
  def change
    add_reference :tags, :pon, index: true, foreign_key: true, null:false
  end
end
