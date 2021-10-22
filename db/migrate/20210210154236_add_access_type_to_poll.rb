class AddAccessTypeToPoll < ActiveRecord::Migration
  def up
    add_column :polls, :access_type, :integer
  end

  def down
    remove_column :polls, :access_type
  end
end
