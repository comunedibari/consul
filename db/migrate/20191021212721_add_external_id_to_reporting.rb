class AddExternalIdToReporting < ActiveRecord::Migration
  def change
    add_column :reportings, :external_id, :integer, null: true
  end
end
