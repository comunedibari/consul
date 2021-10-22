class AddPonRefToSpendingProposals < ActiveRecord::Migration
  def change
    add_reference :spending_proposals, :pon, index: true, foreign_key: true, null: false
  end
end
