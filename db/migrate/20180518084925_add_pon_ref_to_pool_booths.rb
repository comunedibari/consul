class AddPonRefToPoolBooths < ActiveRecord::Migration
  def change
    add_reference :poll_booths, :pon, index: true, foreign_key: true, null: false
  end
end
