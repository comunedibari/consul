class AddFlagPrivacyToUsers < ActiveRecord::Migration
  def up
    add_column :users, :privacy,  :boolean, default: false
    User.update_all ["privacy = false"]
  end

  def down
    remove_column :users, :privacy
  end
end
