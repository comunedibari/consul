class Poll::Answer < ActiveRecord::Base

  belongs_to :question, -> { with_hidden }
  belongs_to :author, ->   { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  has_many :poll_questions

  delegate :poll, :poll_id, to: :question

  validates :question, presence: true
  validates :author, presence: true
  validates :answer, presence: true
  validates :content, presence: false


  validates :answer, inclusion: { in: ->(a) { a.question.question_group.question_answers.pluck(:title) }},
                     unless: ->(a) { a.question.blank? }

  scope :by_author, ->(author_id) { where(author_id: author_id) }
  scope :by_question, ->(question_id) { where(question_id: question_id) }
  scope :by_token, ->(token) { where(token: token) }

  def pon_id
    question.poll.pon_id
  end

  def record_voter_participation(token)

    poll_voter = Poll::Voter.find_by token: token

    # Se esiste già un poll_voter, si tratta di un voter invitato dall'esterno
    # Altrimenti và creato con l'origin "web"
    if poll_voter.nil?
      Poll::Voter.create!(user: author, poll: poll, origin: "web", token: token)
    end

  end
end
