class AddExternalUrlToComments < ActiveRecord::Migration
  def change
    add_column :comments, :external_url, :string
  end
end
