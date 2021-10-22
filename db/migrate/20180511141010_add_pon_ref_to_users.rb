class AddPonRefToUsers < ActiveRecord::Migration
  def change
    add_reference :users, :pon, index: true, foreign_key: true, null:false
  end
end
