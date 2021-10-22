class ChangeDefaultValueForUsers < ActiveRecord::Migration
  def up
    change_column_default(:users, :public_activity, false)
    change_column_default(:users, :newsletter, false)
    change_column_default(:users, :email_digest, false)
    change_column_default(:users, :email_on_direct_message, false)
    change_column_default(:users, :public_map, false)
  end

  def down
    change_column_default(:users, :public_activity, true)
    change_column_default(:users, :newsletter, true)
    change_column_default(:users, :email_digest, true)
    change_column_default(:users, :email_on_direct_message, true)
    change_column_default(:users, :public_map, true)
  end
end

