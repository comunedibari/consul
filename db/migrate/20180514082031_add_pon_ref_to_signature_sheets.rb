class AddPonRefToSignatureSheets < ActiveRecord::Migration
  def change
    add_reference :signature_sheets, :pon, index: true, foreign_key: true, null: false
  end
end
