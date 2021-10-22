class AddExternalUrlToDebates < ActiveRecord::Migration
  def change
    add_column :debates, :external_url, :string
  end
end
