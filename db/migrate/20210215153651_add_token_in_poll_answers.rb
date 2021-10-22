class AddTokenInPollAnswers < ActiveRecord::Migration
  def up
    add_column :poll_answers, :token, :text
  end

  def down
    remove_column :poll_answers, :token
  end
end
