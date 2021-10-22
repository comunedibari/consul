class Collaboration::Agreement < ActiveRecord::Base

     include Rails.application.routes.url_helpers
     include Flaggable
     include Taggable
     include Conflictable
     include Measurable
     include Sanitizable
     include Searchable
     include Filterable
     include HasPublicAuthor
     include Graphqlable
     include Followable
     #include Communitable
     include Imageable
     include Mappable
     include Notifiable
     include Documentable
     include Galleryable
     include ActsAsParanoidAliases
     include EmbedVideosHelper
     include Relationable
     include Moderable
     include Eventable
     include Sectorable
     include Sociable




  documentable max_documents_allowed: 3,
              max_file_size: 3.megabytes#,
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
  
  imageable max_images_allowed: 6

  acts_as_paranoid column: :hidden_at
  belongs_to :geozone
  belongs_to :pon
  
  PHASES_AND_PUBLICATIONS = %i(debate_phase allegations_phase proposals_phase draft_publication result_publication).freeze

  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  validates :author, presence: true
  validates :description, presence: true, length: { maximum: Collaboration::Agreement.description_max_length }
  #has_many :draft_versions, -> { order(:id) }, class_name: 'Collaboration::DraftVersion',
  #                                             foreign_key: 'collaboration_agreement_id', dependent: :destroy
  #has_one :final_draft_version, -> { where final_version: true, status: 'published' }, class_name: 'Collaboration::DraftVersion',
  #                                                                                     foreign_key: 'collaboration_agreement_id'
  has_many :comments, as: :commentable, dependent: :destroy 
  has_many :agreement_requirements, -> { order(:id) }, class_name: 'Collaboration::AgreementRequirement', foreign_key: 'collaboration_agreement_id', dependent: :destroy
  # naviga relazione su relazione (join, include a 3)
  has_many :subscriptions, class_name: 'Collaboration::Subscription',  foreign_key: 'collaboration_agreement_id'
  has_many :subscriptioners, through: :subscriptions, source: :user
  has_many :agreement_notifications, class_name: 'Collaboration::AgreementNotification',  foreign_key: 'collaboration_agreement_id', dependent: :destroy

  #has_one :process_chance, class_name: 'Collaboration::ProcessChance',  foreign_key: 'collaboration_agreement_id'  

  
  #has_one :process_sgap, class_name: 'Collaboration::ProcessSgap',  foreign_key: 'collaboration_agreement_id'  
  #has_many :process_phases, -> { order(:id) }, class_name: 'Collaboration::ProcessPhase', foreign_key: 'collaboration_agreement_id', dependent: :destroy
  #has_many :process_finance, -> { order(:id) }, class_name: 'Collaboration::ProcessFinance', foreign_key: 'collaboration_agreement_id', dependent: :destroy

  has_one  :sector_content, as: :sectorable, dependent: :destroy

  
  
  
  #accepts_nested_attributes_for :collaboration_substription, allow_destroy: true, reject_if: :all_blank
  #accepts_nested_attributes_for :process_chance, allow_destroy: true, reject_if: :all_blank
  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :debate_start_date, presence: true, if: :debate_end_date?
  validates :debate_end_date, presence: true, if: :debate_start_date?
  validates :allegations_start_date, presence: true, if: :allegations_end_date?
  validates :allegations_end_date, presence: true, if: :allegations_start_date?
  validates :proposals_phase_end_date, presence: true, if: :proposals_phase_start_date?
  validate :valid_date_ranges
  #validate :valid_subscription

  scope :opens, -> { where("start_date <= ? and end_date >= ?", Date.current, Date.current).order('id DESC') }
  scope :next, -> { where("start_date > ?", Date.current).order('id DESC') }
  scope :past, -> { where("end_date < ?", Date.current).order('id DESC') }
  scope :waiting_moderation, -> { where("moderation_entity = 2").order('id DESC') }

  scope :agreement_type, ->(agreement_type_list) { where("agreement_type in (?)", agreement_type_list) }
  #tipologie di process alternative
  scope :process_standard, -> { where(agreement_type: 1) }
  scope :process_work, -> { where(agreement_type: 2) }
  scope :process_chance, -> { where(agreement_type: 3) }
  scope :agreement_all_type, -> { }

  scope :published, -> { where(published: true) }

  scope :for_render,               -> { includes(:tags) }
  scope :featured,                 -> { }
  scope :by_user_pon,              -> { where(pon_id: User.pon_id)}
  scope :by_user,                  ->(user) { where(author: user).where('moderation_entity in (1,2)') }
  scope :sort_by_agreement_type,     -> { reorder(agreement_type: :desc) }
  scope :sort_by_confidence_score, -> { reorder(confidence_score: :desc) }
  scope :sort_by_created_at,       -> { reorder(created_at: :desc) }
  scope :sort_by_start_date,       -> { reorder(start_date: :desc) }
  scope :sort_by_random,           -> { reorder("RANDOM()") }
  scope :sort_by_relevance,        -> { all }
  scope :sort_by_recommendations,  -> { }
  scope :last_week,                -> { where("created_at >= ?", 7.days.ago)}
  scope :public_for_api,           -> { all.published.mod_approved }
 
  before_save :test 



   
  def self.to_csv
    CSV.generate(:col_sep => ";") do |csv|
      csv << %w{ id titolo descrizione data_inizio_patto data_fine_patto numero_commenti numero_adesioni_ricevute municipio zona latitudine longitudine} 
      all.each do |e|
        csv << [
          e.id,
          e.title, 
          e.description,
          e.start_date.strftime('%Y-%m-%d %H:%M:%S'), 
          e.end_date.strftime('%Y-%m-%d %H:%M:%S'), 
          e.comments_count ? e.comments_count : "-", 
          e.subscriptions_count ? e.subscriptions_count : "-", 
          e.pon.name,
          e.geozone ? e.geozone.name : nil,
          e.map_location ? e.map_location.latitude : nil, 
          e.map_location ? e.map_location.longitude : nil        
        ]
      end
    end
  end

  def open?
    start_date <= Date.current && end_date >= Date.current
  end

  def past?
    end_date < Date.current
  end

  def next?
    start_date > Date.current
  end 
 

  def already_subscription?(user)
    self.subscriptions.where(user_id: user.id).exists?
  end

  # def subscriptions_count
  #  self.subscriptions_count 
  # end  

  def count_sub
    Collaboration::Subscription.select(:user_id).where(collaboration_agreement_id: id).count
    #update_attribute(:subscriptions_count, number_subscriptions).to_s
  end

  def test 
    logger.debug "-------test"
  end 

  def to_param
    "#{id}-#{title}".parameterize
  end
    
  def editable_by?(user)
    (
      (author_id == user.id) || (user.pon_id== self.pon_id && user.can_moderate?)
    )
  end

  def notifications
    agreement_notifications
  end

  def self.recommendations(user)
    tagged_with(user.interests, any: true)
      .where("author_id != ?", user.id)
      .unsuccessful
      .not_followed_by_user(user)
      .not_archived
      .not_supported_by_user(user)
  end

  def self.agreements_orders(user)
    orders = %w{agreement_type created_at}
    orders << "recommendations" if user.present?
    orders
  end

  def moderable_comments_by?(user)
    user && user.pon_id==self.pon_id && user.can_moderate?
  end  


  def debate_phase
    Collaboration::Agreement::Phase.new(debate_start_date, debate_end_date, debate_phase_enabled)
  end

  def allegations_phase
    Collaboration::Agreement::Phase.new(allegations_start_date, allegations_end_date, allegations_phase_enabled)
  end

  def proposals_phase
    Collaboration::Agreement::Phase.new(proposals_phase_start_date, proposals_phase_end_date, proposals_phase_enabled)
  end

  def draft_publication
    Collaboration::Agreement::Publication.new(draft_publication_date, draft_publication_enabled)
  end

  def result_publication
    Collaboration::Agreement::Publication.new(result_publication_date, result_publication_enabled)
  end

  def enabled_phases_and_publications_count
    PHASES_AND_PUBLICATIONS.count { |process| send(process).enabled? }
  end


  #followable methods
  def self.not_followed_by_user(user)
    where.not(id: followed_by_user(user).pluck(:id))
  end

  def users_to_notify
    (subscriptioners + followers).uniq
  end


  def already_subscribed(user)
    self.subscriptions.where(user: user).count > 0
  end

  def subscription(user)
    self.subscriptions.where(user: user).first()
  end

  # def valid_subscription
  #   if already_subscribed 
  #     #ok
  #   else
  #     errors.add(:min_price, I18n.t('verification.collaboration.subscription.already_subscription'))
  #   end
    
  # end

 
  def status
    today = Date.current

    if in_approval?
      :waiting_approval
    elsif today < start_date
      :planned
    elsif end_date < today
      :closed
    else
      :open
    end
  end

  def searchable_values
    { title              => 'A',
      author.username    => 'B',
      tag_list.join(' ') => 'B',
      #geozone.try(:name) => 'B',
      summary            => 'C',
      description        => 'D',
    }  
  end

  def self.search(terms)
    pg_search(terms)
  end

  def after_hide
    tags.each{ |t| t.decrement_custom_counter_for('Collaboration::Agreement') }
  end

  def after_restore
    tags.each{ |t| t.increment_custom_counter_for('Collaboration::Agreement') }
  end

  


  private

    def valid_date_ranges
      errors.add(:end_date, :invalid_date_range) if end_date && start_date && end_date < start_date
      errors.add(:debate_end_date, :invalid_date_range) if debate_end_date && debate_start_date && debate_end_date < debate_start_date
      if allegations_end_date && allegations_start_date && allegations_end_date < allegations_start_date
        errors.add(:allegations_end_date, :invalid_date_range)
      end
    end

end
