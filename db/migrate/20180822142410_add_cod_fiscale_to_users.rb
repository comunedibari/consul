class AddCodFiscaleToUsers < ActiveRecord::Migration
  def change
    add_column :users, :cod_fiscale, :string
  end
end
