class AddInvitationSentToPollVoters < ActiveRecord::Migration
  def up
    add_column :poll_voters, :invitation_sent, :boolean, :default => false
  end

  def down
    remove_column :poll_voters, :invitation_sent
  end
end
