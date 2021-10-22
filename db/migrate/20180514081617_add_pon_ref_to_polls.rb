class AddPonRefToPolls < ActiveRecord::Migration
  def change
    add_reference :polls, :pon, index: true, foreign_key: true, null: false
  end
end
