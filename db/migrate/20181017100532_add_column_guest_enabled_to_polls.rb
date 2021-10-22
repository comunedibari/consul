class AddColumnGuestEnabledToPolls < ActiveRecord::Migration
  def change
    add_column :polls, :guest_enabled, :boolean, null: true
  end
end
