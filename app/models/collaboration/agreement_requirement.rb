class Collaboration::AgreementRequirement < ActiveRecord::Base
  self.table_name = "agreement_requirements"
 
  include ActsAsParanoidAliases
  include Notifiable
  include Documentable

  acts_as_votable
  acts_as_paranoid column: :hidden_at
 

  belongs_to :collaboration_agreement, class_name: 'Collaboration::Agreement', foreign_key: 'collaboration_agreement_id'
  
  validates :title, presence: true
  







  documentable max_documents_allowed: 2,
              max_file_size: 3.megabytes#,
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
  include Imageable
  imageable max_images_allowed: 2

  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  #belongs_to :process, class_name: 'Legislation::Process', foreign_key: 'legislation_process_id'

  has_many :question_options, -> { order(:id) }, class_name: 'Legislation::QuestionOption', foreign_key: 'legislation_question_id',
                                                 dependent: :destroy, inverse_of: :question
  #has_many :answers, class_name: 'Legislation::Answer', foreign_key: 'legislation_question_id', dependent: :destroy, inverse_of: :question
  has_many :comments, as: :commentable, dependent: :destroy

  accepts_nested_attributes_for :question_options, reject_if: proc { |attributes| attributes[:value].blank? }, allow_destroy: true

  validates :title, presence: true

  scope :sorted, -> { order('id ASC') }


  def editable_by?(user)
    author_id == user.id || user.administrator?
  end

  def next_question_id
    @next_question_id ||= process.questions.where("id > ?", id).sorted.limit(1).pluck(:id).first
  end

  def first_question_id
    @first_question_id ||= process.questions.sorted.limit(1).pluck(:id).first
  end

  def answer_for_user(user)
    answers.where(user: user).first
  end

  def comments_for_verified_residents_only?
    true
  end

  def comments_closed?
    !comments_open?
  end

  def comments_open?
    process.debate_phase.open?
  end

  protected

   

end
