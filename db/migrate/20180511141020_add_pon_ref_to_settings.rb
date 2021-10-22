class AddPonRefToSettings < ActiveRecord::Migration
  def change
    add_reference :settings, :pon, index: true, foreign_key: true, null:false
  end
end
