class AddPonRefToProposals < ActiveRecord::Migration
  def change
    add_reference :proposals, :pon, index: true, foreign_key: true, null:false
  end
end
