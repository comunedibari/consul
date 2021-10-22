class AddCfRapprLegaleToSectors < ActiveRecord::Migration
  def change
    add_column :sectors, :cf_rappr_legale, :string
  end
end
