class AddAgreementToMapLocation < ActiveRecord::Migration
  def change
    add_column :map_locations, :agreement_id, :integer
    add_index :map_locations, :agreement_id
  end
end
