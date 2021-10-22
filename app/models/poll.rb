class Poll < ActiveRecord::Base
  include Imageable
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases
  include Notifiable
  include Documentable
  include Eventable
  include Sociable




  documentable max_documents_allowed: 3,
              max_file_size: 3.megabytes#,
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")

  imageable max_images_allowed: 1

  RECOUNT_DURATION = 1.week

  has_many :booth_assignments, class_name: "Poll::BoothAssignment"
  has_many :booths, through: :booth_assignments
  has_many :partial_results, through: :booth_assignments
  has_many :recounts, through: :booth_assignments
  has_many :voters
  has_many :officer_assignments, through: :booth_assignments
  has_many :officers, through: :officer_assignments
  has_many :questions
  has_many :comments, as: :commentable

  belongs_to :access_type, class_name: 'LevelActivitiesType', foreign_key: 'access_type'

  has_and_belongs_to_many :geozones
  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  belongs_to :geozone
  validates :name, presence: true
  validates :description, presence: true

  validate :date_range

  scope :current,  -> { where('starts_at <= ? and ? <= ends_at', Date.current.beginning_of_day, Date.current.beginning_of_day) }
  scope :incoming, -> { where('? < starts_at', Date.current.beginning_of_day) }
  scope :expired,  -> { where('ends_at < ?', Date.current.beginning_of_day) }
  scope :recounting, -> { Poll.where(ends_at: (Date.current.beginning_of_day - RECOUNT_DURATION)..Date.current.beginning_of_day) }
  scope :published, -> { where('published = ?', true) }
  scope :by_geozone_id, ->(geozone_id) { where(geozones: {id: geozone_id}.joins(:geozones)) }
  scope :public_for_api, -> { all.published }

  scope :sort_for_list, -> { order(:geozone_restricted, :starts_at, :name) }
  belongs_to :pon
  scope :by_user_pon,              -> { where(pon_id: User.pon_id)}


  def self.to_csv
    CSV.generate(:col_sep => ";") do |csv|
      csv << %w{ id titolo descrizione sommario data_inizio data_fine data_creazione numero_commenti municipio zona}
      all.each do |e|
        csv << [
          e.id,
          e.name,
          e.description,
          e.summary,
          e.starts_at.strftime('%Y-%m-%d %H:%M:%S'),
          e.ends_at.strftime('%Y-%m-%d %H:%M:%S'),
          e.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          e.comments_count ? e.comments_count : "-",
          e.pon.name,
          e.geozone ? e.geozone.name : nil,
        ]
      end
    end
  end

  def title
    name
  end

  def start_date
    starts_at
  end

  def end_date
    ends_at
  end

  def current?(timestamp = Date.current.beginning_of_day)
    starts_at <= timestamp && timestamp <= ends_at
  end

  def incoming?(timestamp = Date.current.beginning_of_day)
    timestamp < starts_at
  end

  def expired?(timestamp = Date.current.beginning_of_day)
    ends_at < timestamp
  end

  def self.current_or_incoming
    current + incoming
  end

  def self.current_or_recounting_or_incoming
    current + recounting + incoming
  end

  def voted(user)

  end

  def confirmable_by?(user)
    social_service = Setting.where(key: 'service_social.polls').where("value = 'true' ").where(pon_id: user.pon_id).first

    if (user.provider.present? && user.is_social? && !social_service) || user.administrator?
        return false
    end

    return true
  end

  def answerable_by?(user)
    user.present? && user.level_two_or_three_verified? && current? && (!geozone_restricted || geozone_ids.include?(user.geozone_id))
  end

  def self.answerable_by(user)
    return none if user.nil? || user.unverified?
    current.joins('LEFT JOIN "geozones_polls" ON "geozones_polls"."poll_id" = "polls"."id"')
           .where('geozone_restricted = ? OR geozones_polls.geozone_id = ?', false, user.geozone_id)
  end


  def votable_by?(user)
    !document_has_voted?(user.document_number, user.document_type)
  end

  def document_has_voted?(document_number, document_type)
    voters.where(document_number: document_number, document_type: document_type).exists?
  end

  def vote_has_been_confirmed?(user)
    if user
      poll_questions = Poll::Question.where(poll_id: self.id)
      Poll::Answer.where(question_id: poll_questions.ids, submitted: true, author: user).exists?
    else
      false
    end
  end

  def voted_in_booth?(user)
    Poll::Voter.where(poll: self, user: user, origin: "booth").exists?
  end

  def voted_in_web?(user)
    Poll::Voter.where(poll: self, user: user, origin: "web").exists?
  end

  def moderable_comments_by?(user)
    user && user.pon_id==self.pon_id && user.can_moderate?
  end

  def date_range
    unless starts_at.present? && ends_at.present? && starts_at <= ends_at
      errors.add(:starts_at, I18n.t('errors.messages.invalid_date_range'))
    end
  end

end
