class AddPonRefToGeozones < ActiveRecord::Migration
  def change
    add_reference :geozones, :pon, index: true, foreign_key: true, null:false
  end
end
