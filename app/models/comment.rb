class Comment < ActiveRecord::Base
  include Merit
  has_merit

  include Flaggable
  include HasPublicAuthor
  include Graphqlable
  include Notifiable
  include Documentable
  include Sectorable 
  include Moderable

  documentable max_documents_allowed: 2,
              max_file_size: 3.megabytes#,
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
  include Imageable
  imageable max_images_allowed: 4

  COMMENTABLE_TYPES = %w(Event Debate Reporting Proposal Crowdfunding Budget::Investment Poll Topic Legislation::Question
    Legislation::Annotation Legislation::Proposal Collaboration::Agreement).freeze


  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases
  acts_as_votable
  has_ancestry touch: true

  attr_accessor :as_moderator, :as_administrator

  validates :body, presence: true
  validates :user, presence: true

  validates :commentable_type, inclusion: { in: COMMENTABLE_TYPES }

  validate :validate_body_length
  validate :comment_valuation, if: -> { valuation }

  belongs_to :commentable, -> { with_hidden }, polymorphic: true, counter_cache: true
  belongs_to :user, -> { with_hidden }
  scope :by_user_pon,          -> { joins(:user).where("users.pon_id = ?", User.pon_id)}
  scope :by_comment_pon,          -> { where(pon_id:  User.pon_id)}

  has_many :vote, as: :votable




  before_save :calculate_confidence_score

  scope :for_render, -> { with_hidden.includes(user: :organization) }
  scope :with_visible_author, -> { joins(:user).where("users.hidden_at IS NULL") }
  scope :not_as_admin_or_moderator, -> do
    where("administrator_id IS NULL").where("moderator_id IS NULL")
  end
  scope :sort_by_flags, -> { order(flags_count: :desc, updated_at: :desc) }
  scope :public_for_api, -> do
    not_valuations
      .where(%{(comments.commentable_type = 'Debate' and comments.commentable_id in (?)) or
            (comments.commentable_type = 'Proposal' and comments.commentable_id in (?)) or
            (comments.commentable_type = 'Crowdfunding' and comments.commentable_id in (?)) or
            (comments.commentable_type = 'Reporting' and comments.commentable_id in (?)) or
            (comments.commentable_type = 'Event' and comments.commentable_id in (?)) or
            (comments.commentable_type = 'Poll' and comments.commentable_id in (?)) or
            (comments.commentable_type = 'Collaboration::Agreement' and comments.commentable_id in (?))},
          Debate.public_for_api.pluck(:id),
          Proposal.public_for_api.pluck(:id),
          Crowdfunding.public_for_api.pluck(:id),
          Reporting.public_for_api.pluck(:id),
          Event.public_for_api.pluck(:id),
          Poll.public_for_api.pluck(:id),
          Collaboration::Agreement.public_for_api.pluck(:id))
          
  end

  scope :sort_by_most_voted, -> { order(confidence_score: :desc, created_at: :desc) }
  scope :sort_descendants_by_most_voted, -> { order(confidence_score: :desc, created_at: :asc) }

  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :sort_descendants_by_newest, -> { order(created_at: :desc) }

  scope :sort_by_oldest, -> { order(created_at: :asc) }
  scope :sort_descendants_by_oldest, -> { order(created_at: :asc) }

  scope :not_valuations, -> { where(valuation: false) }

  after_create :call_after_commented

  def self.build(commentable, user, body, p_id = nil, valuation = false)
    new(commentable: commentable,
        user_id:     user.id,
        body:        body,
        parent_id:   p_id,
        valuation:   valuation)
  end

  def self.find_commentable(c_type, c_id)
    c_type.constantize.find(c_id)
  end

  def author_id
    user_id
  end

  def author
    user
  end

  def author=(author)
    self.user = author
  end

  def total_votes
    cached_votes_total
  end

  def total_likes
    cached_votes_up
  end

  def total_dislikes
    cached_votes_down
  end

  def as_administrator?
    administrator_id.present?
  end

  def as_moderator?
    moderator_id.present?
  end

  def after_hide
    #commentable_type.constantize.with_hidden.reset_counters(commentable_id, :comments)
    obj = commentable_type.constantize.with_hidden.where(id: commentable_id).first
    n_comm = Comment.where("commentable_type = ? AND commentable_id = ?",commentable_type ,commentable_id).where(moderation_entity: 1).count
    obj.comments_count = n_comm
    obj.save
  end

  def after_restore
    #commentable_type.constantize.with_hidden.reset_counters(commentable_id, :comments)
    obj = commentable_type.constantize.with_hidden.where(id: commentable_id).first
    n_comm = Comment.where("commentable_type = ? AND commentable_id = ?",commentable_type ,commentable_id).where(moderation_entity: 1).count
    obj.comments_count = n_comm
    obj.save
  end

  def reply?
    !root?
  end

  def call_after_commented
    commentable.try(:after_commented)
  end

  def self.body_max_length
    Setting['comments_body_max_length', User.pon_id].to_i
  end

  def self.documentable
    documentable
  end
  
  def calculate_confidence_score
    self.confidence_score = ScoreCalculator.confidence_score(cached_votes_total,
                                                             cached_votes_up)
  end


  private

    def validate_body_length
      validator = ActiveModel::Validations::LengthValidator.new(
        attributes: :body,
        maximum: Comment.body_max_length)
      validator.validate(self)
    end

    def comment_valuation
      unless author.can?(:comment_valuation, commentable)
        errors.add(:valuation, :cannot_comment_valuation)
      end
    end
end
