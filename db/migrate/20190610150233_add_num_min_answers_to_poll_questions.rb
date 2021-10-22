class AddNumMinAnswersToPollQuestions < ActiveRecord::Migration
  def up
    add_column :poll_questions, :num_min_answers,  :integer, default: 0
  end

  def down
    remove_column :poll_questions, :num_min_answers
  end
end
