class Poll::QuestionType < ActiveRecord::Base

  has_many :poll_questions, class_name: 'Poll::Question', foreign_key: 'poll_question_type_id'


end
