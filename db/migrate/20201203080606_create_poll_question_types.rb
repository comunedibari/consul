class CreatePollQuestionTypes < ActiveRecord::Migration
  def change
    create_table :poll_question_types do |t|
      t.string   "name"
    end
  end
end
