class AddPonRefToDebates < ActiveRecord::Migration
  def change
    add_reference :debates, :pon, index: true, foreign_key: true, null: false
  end
end
