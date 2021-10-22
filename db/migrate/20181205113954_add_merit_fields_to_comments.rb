class AddMeritFieldsToComments < ActiveRecord::Migration
  def change
    add_column :comments, :sash_id, :integer
    add_column :comments, :level,   :integer, :default => 0
  end
end
