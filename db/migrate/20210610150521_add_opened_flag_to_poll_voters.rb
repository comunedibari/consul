class AddOpenedFlagToPollVoters < ActiveRecord::Migration
  def up
    add_column :poll_voters, :opened, :boolean, :default => false
  end

  def down
    remove_column :poll_voters, :opened
  end
end
