class Poll::Question::Answer < ActiveRecord::Base
  include Galleryable
  include Documentable
  include Imageable
  include Measurable
  imageable max_images_allowed: 4
  

  documentable max_documents_allowed: 3,
              max_file_size: 3.megabytes#,
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
 
  accepts_nested_attributes_for :documents, allow_destroy: true

  belongs_to :question, class_name: 'Poll::Question', foreign_key: 'question_id'
  has_many :videos, class_name: 'Poll::Question::Answer::Video'


  validates :title, presence: true,  uniqueness: { scope: [:title, :question_id] }

  validates :given_order, presence: true, uniqueness: { scope: :question_id }

  before_validation :set_order, on: :create

  def author_id
    question.author.id
  end

  def pon_id
    question.poll.pon_id
  end

  def description
    super.try :html_safe
  end

  def self.order_answers(ordered_array)
    ordered_array.each_with_index do |answer_id, order|
      find(answer_id).update_attribute(:given_order, (order + 1))
    end
  end

  def set_order
    self.given_order = self.class.last_position(question_id) + 1
  end

  def self.last_position(question_id)
    where(question_id: question_id).maximum('given_order') || 0
  end

  def total_votes
    Poll::Answer.where(question_id: question, answer: title).where(submitted: true).count
  end

  def total_votes_by_question question_id
    Poll::Answer.where(question_id: question_id, answer: title).where(submitted: true).count
  end

  def most_voted?
    most_voted
  end

  def total_votes_percentage
    question.answers_total_votes.zero? ? 0 : (total_votes * 100) / question.answers_total_votes
  end

  def total_votes_percentage_by_question question_child
    question_child.answers_total_votes.zero? ? 0 : (total_votes * 100).to_f / question_child.answers_total_votes
  end

  def set_most_voted
    answers = question.question_answers
                      .map { |a| Poll::Answer.where(question_id: a.question, answer: a.title).count }
    is_most_voted = answers.none?{ |a| a > total_votes }

    update(most_voted: is_most_voted)
  end

  def set_most_voted_by_question question_child
    answers = question_child.question_group.question_answers
                      .map { |a| Poll::Answer.where(question_id: a.question, answer: a.title).count }
    is_most_voted = answers.none?{ |a| a > total_votes_by_question(question_child.id) }

    update(most_voted: is_most_voted)
  end

end
