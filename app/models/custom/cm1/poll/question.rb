class Poll::Question < ActiveRecord::Base
  include Measurable
  include Searchable
  include Imageable
  include Documentable
  include Galleryable

  documentable max_documents_allowed: 3,
              max_file_size: 3.megabytes#,
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
  imageable max_images_allowed: 3

  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  belongs_to :poll
  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'

  has_many :comments, as: :commentable
  has_many :answers, class_name: 'Poll::Answer'
  
  has_many :partial_results

  belongs_to :question_optional, class_name: 'Poll::Question', foreign_key: 'question_optional_id'
  belongs_to :question_group, class_name: 'Poll::Question', foreign_key: 'group_id'

  belongs_to :poll_question_type, class_name: 'Poll::QuestionType', foreign_key: 'poll_question_type_id'

  has_many :question_answers, -> { order 'given_order asc' }, class_name: 'Poll::Question::Answer'
  belongs_to :poll_question_answer, class_name: 'Poll::Question::Answer'

  belongs_to :proposal

  #validates :title, presence: true
  validates :author, presence: true
  validates :poll_id, presence: true
  
  validate :num_min_max_answers

  validates :title, length: { minimum: 4 }

  scope :by_poll_id,    ->(poll_id) { where(poll_id: poll_id) }

  #scope :sort_for_list, -> { order('poll_questions.proposal_id IS NULL', :created_at)}
  scope :sort_for_list, -> { order('poll_questions.proposal_id IS NULL', :id)}
  scope :for_render,    -> { includes(:author, :proposal) }
  scope :by_user_pon,   -> {Poll::Question.joins(:poll).where("polls.pon_id = ?",User.pon_id)}



  def pon_id
    self.poll.pon_id
  end

  def comments_count
    self.comments.where(moderation_entity: 1).count
  end

  def answers_count_from_users
    self.answers.count
  end

  def self.search(params)
    results = all
    results = results.by_poll_id(params[:poll_id]) if params[:poll_id].present?
    results = results.pg_search(params[:search])   if params[:search].present?
    results
  end

  def searchable_values
    { title                 => 'A',
      group_title           => 'A',
      proposal.try(:title)  => 'A',
      author.username       => 'C',
      author_visible_name   => 'C' }
  end

  def copy_attributes_from_proposal(proposal)
    if proposal.present?
      self.author = proposal.author
      self.author_visible_name = proposal.author.name
      self.proposal_id = proposal.id
      self.title = proposal.title
    end
  end

  delegate :answerable_by?, to: :poll

  def self.answerable_by(user)
    return none if user.nil? || user.unverified?
    where(poll_id: Poll.answerable_by(user).pluck(:id))
  end

  def answers_total_votes
    question_group.question_answers.map { |a| Poll::Answer.where(question_id: self, answer: a.title).where(submitted: true).count }.sum
  end

  def num_min_max_answers
    if !self.id.nil?
      unless num_min_answers <= num_max_answers
        errors.add(:num_min_answers, I18n.t('errors.messages.num_min_answers'))
      end
    end
  end

end
