class AddCrmFlagToPolls < ActiveRecord::Migration
  def up
    add_column :polls, :ext_use, :boolean, :default => false
  end

  def down
    remove_column :polls, :ext_use
  end
end
