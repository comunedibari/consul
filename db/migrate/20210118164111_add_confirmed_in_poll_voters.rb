class AddConfirmedInPollVoters < ActiveRecord::Migration
  def up
    add_column :poll_voters, :confirmed, :boolean, default: false
    Poll::Voter.update_all ["confirmed = true"]
  end

  def down
    remove_column :poll_voters, :confirmed
  end
end
