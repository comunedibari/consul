class AddPollQuestionTypeIdQuestionOptionalIdPollAnswerIdToPollQuestions < ActiveRecord::Migration
  def up
    add_reference :poll_questions, :poll_question_type, index: true, foreign_key: true, null: true
    add_reference :poll_questions, :poll_question_answer, index: true, foreign_key: true, null: true
    add_reference :poll_questions, :question_optional, index: true, null: true
  end

  def down
    remove_reference :poll_questions, :poll_question_type
    remove_reference :poll_questions, :poll_question_answer
    remove_reference :poll_questions, :question_optional
  end
end
