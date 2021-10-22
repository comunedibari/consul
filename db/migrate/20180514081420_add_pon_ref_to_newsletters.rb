class AddPonRefToNewsletters < ActiveRecord::Migration
  def change
    add_reference :newsletters, :pon, index: true, foreign_key: true, null: false
  end
end
