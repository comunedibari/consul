class AddNumMaxAnswersToPollQuestions < ActiveRecord::Migration
  def change
    add_column :poll_questions, :num_max_answers, :integer, default: "1"
  end
end
