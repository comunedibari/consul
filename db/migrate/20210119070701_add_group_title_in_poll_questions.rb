class AddGroupTitleInPollQuestions < ActiveRecord::Migration
  def up
    add_column :poll_questions, :group_title, :text
    add_column :poll_questions, :group_id, :integer
    Poll::Question.update_all ["group_id = id"]
  end

  def down
    remove_column :poll_questions, :group_title
    remove_column :poll_questions, :group_id
  end
end
