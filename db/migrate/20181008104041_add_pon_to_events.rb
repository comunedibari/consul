class AddPonToEvents < ActiveRecord::Migration
  def change
    add_reference :events, :pon, index: true, foreign_key: true, null:false
  end
end
