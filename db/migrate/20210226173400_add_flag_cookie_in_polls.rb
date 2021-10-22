class AddFlagCookieInPolls < ActiveRecord::Migration
  def up
    add_column :polls, :flag_cookie, :boolean, default: false
    Poll.update_all ["flag_cookie = false"]
  end

  def down
    remove_column :polls, :flag_cookie
  end
end
