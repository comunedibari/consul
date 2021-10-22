require 'numeric'
class Event < ActiveRecord::Base

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
    include Moderable
    include Sectorable
    #include Eventable
    include Slottable
    include EmbedVideosHelper
    include Relationable
    include Sociable

    acts_as_votable
    acts_as_paranoid column: :hidden_at
    include ActsAsParanoidAliases

    # Ahoy setup
    #visitable # Ahoy will automatically assign visit_id on create

    attr_accessor :link_required
    
    MAX_SLOTS_FOR_EVENT = 10
    
    documentable max_documents_allowed: 3,
                max_file_size: 3.megabytes#,
                #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
                #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
    imageable max_images_allowed: 3
    belongs_to :geozone
    belongs_to :pon
    belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
    belongs_to :event_type, class_name: 'EventType', foreign_key: 'event_type_id'   
    
    has_many :comments, as: :commentable
    has_many :votes, as: :votable
    has_many :comments, as: :commentable, dependent: :destroy
    has_many :event_notifications, dependent: :destroy

    validates :title, presence: true
    validates :description, presence: true
    #validates :start_event, presence: true
    #validates :end_event, presence: true
    #validate :valid_date_ranges
    validate :event_slots_presence

    before_save :calculate_hot_score, :calculate_confidence_score 

    scope :for_render,               -> { includes(:tags) }
    scope :sort_by_hot_score,        -> { reorder(hot_score: :desc) }
    scope :sort_by_confidence_score, -> { reorder(confidence_score: :desc) }
    scope :sort_by_created_at,       -> { reorder(created_at: :desc) }
    scope :sort_by_most_commented,   -> { reorder(comments_count: :desc) }
    scope :sort_by_random,           -> { reorder("RANDOM()") }
    scope :sort_by_relevance,        -> { all }
    scope :sort_by_flags,            -> { order(flags_count: :desc, updated_at: :desc) }
    scope :sort_by_recommendations,  -> { order(cached_votes_total: :desc) }
    scope :last_week,                -> { where("created_at >= ?", 7.days.ago)}
    scope :featured,                 -> { where("featured_at is not null")}
    scope :public_for_api,           -> { all.mod_approved }
    scope :by_user_pon,              -> { where(pon_id: User.pon_id)}
    scope :event_type, ->(event_type) { where("event_type_id = ?", event_type) }

    scope :last_week,                -> { where("events.created_at >= ?", 7.days.ago)}  
    scope :retired,                  -> { where.not(retired_at: nil) }
    scope :not_retired,              -> { where(retired_at: nil) }
    scope :successful,               -> { where("cached_votes_up >= ?", Proposal.votes_needed_for_success) }
    scope :unsuccessful,             -> { where("cached_votes_up < ?", Proposal.votes_needed_for_success) }
    scope :not_supported_by_user,    ->(user) { where.not(id: user.find_voted_items(votable_type: "Proposal").compact.map(&:id)) }
  
    def self.to_csv
        CSV.generate(:col_sep => ";") do |csv|
          csv << %w{ id tipologia_evento titolo descrizione data_inizio_evento data_fine_evento data_creazione numero_commenti numero_voti_favorevoli numero_voti_sfavorevoli municipalità zona latitudine longitudine} 
          all.each do |e|
            csv << [
              e.id,
              e.event_type.event_category, 
              e.title, 
              e.description,
              e.start_event.strftime('%Y-%m-%d %H:%M:%S'), 
              e.end_event.strftime('%Y-%m-%d %H:%M:%S'), 
              e.created_at.strftime('%Y-%m-%d %H:%M:%S'), 
              e.comments_count ? e.comments_count : "-", 
              e.cached_votes_up ? e.cached_votes_up : "-",
              e.cached_votes_down ? e.cached_votes_up : "-",
              e.pon.name,
              e.geozone ? e.geozone.name : nil,
              e.map_location ? e.map_location.latitude : nil, 
              e.map_location ? e.map_location.longitude : nil  
            ]
          end
        end
    end
    


    def max_slots
        MAX_SLOTS_FOR_EVENT
    end

    def url
        event_path(self)
    end

    def self.recommendations(user)
        tagged_with(user.interests, any: true)
        .where("author_id != ?", user.id)
    end

    def searchable_values
        { 
        title              => 'A',
        author.username    => 'B',
        tag_list.join(' ') => 'B',
        description        => 'D',
        event_type.event_category      => 'C',
        }
    end

    def self.search(terms)
        pg_search(terms)
    end


  def self.search_by_code(terms)
    matched_code = match_code(terms)
    results = where(id: matched_code[1]) if matched_code
    return results if results.present? && results.first.code == terms
  end

  def self.match_code(terms)
    /\A#{Setting["proposal_code_prefix",User.pon_id]}-\d\d\d\d-\d\d-(\d*)\z/.match(terms)
  end


    def to_param
        "#{id}-#{title}".parameterize
    end

    def likes
        cached_votes_up
    end

    def dislikes
        cached_votes_down
    end

    def total_votes
        cached_votes_total
    end

    def total_anonymous_votes
        cached_anonymous_votes_total
    end

    def editable?(user)
        total_votes <= Setting['max_votes_for_event_edit',user.pon_id].to_i
    end

    
    def register_vote(user, vote_value)
        if votable_by?(user)
            Event.increment_counter(:cached_anonymous_votes_total, id) if user.unverified? && !user.voted_for?(self)
            vote_by(voter: user, vote: vote_value)
        end
    end

    def votable_by?(user)
        return false unless user
        total_votes <= 100 ||
            !user.unverified? ||
            Setting['max_ratio_anon_votes_on_debates',user.pon_id].to_i == 100 ||
            anonymous_votes_ratio < Setting['max_ratio_anon_votes_on_debates',user.pon_id].to_i ||
            user.voted_for?(self)
    end

  def self.recommendations(user)
        tagged_with(user.interests, any: true)
        .where("author_id != ?", user.id)
        .unsuccessful
        .not_followed_by_user(user)
        .not_supported_by_user(user)
  end

  def self.not_followed_by_user(user)
    where.not(id: followed_by_user(user).pluck(:id))
  end

    
    def anonymous_votes_ratio
        return 0 if cached_votes_total == 0
        (cached_anonymous_votes_total.to_f / cached_votes_total) * 100
    end

    def after_commented
        save # updates the hot_score because there is a before_save
    end

    def calculate_hot_score
        self.hot_score = ScoreCalculator.hot_score(created_at,
                                                cached_votes_total,
                                                cached_votes_up,
                                                comments_count)
    end

    def calculate_confidence_score
        self.confidence_score = ScoreCalculator.confidence_score(cached_votes_total,
                                                                cached_votes_up)
    end

    def after_hide
        tags.each{ |t| t.decrement_custom_counter_for('Event') }
    end

    def after_restore
        tags.each{ |t| t.increment_custom_counter_for('Event') }
    end

    def featured?
        featured_at.present?
    end

    def self.events_orders(user)
        orders = %w{hot_score confidence_score created_at relevance}
        orders << "recommendations" if user.present?
        orders
    end

    #add taggs to events
    def self.for_summary
        summary = {}
        categories = ActsAsTaggableOn::Tag.category_names.sort
        geozones   = Geozone.names.sort
        groups = categories + geozones
        groups.each do |group|
        summary[group] = search(group).last_week.sort_by_confidence_score.limit(3)
        end
        summary
    end

    def moderable_comments_by?(user)
        user && user.pon_id==self.pon_id && user.can_moderate?
    end
    def self.recommendations(user)
        tagged_with(user.interests, any: true)
          .where("author_id != ?", user.id)
          .unsuccessful
          .not_followed_by_user(user)
          .not_supported_by_user(user)
    end
    
    def self.not_followed_by_user(user)
        where.not(id: followed_by_user(user).pluck(:id))
    end

    def notifications
        event_notifications
    end
    
    def creable_by?(user)
        # se sei un utente social e se il servizio è attivo per utenti social 
        #social_user = Identity.where("user_id =?",user.id)

        social_service = Setting.where(key: 'service_social.events').where("value = 'true' ").where(pon_id: user.pon_id).first
        
        if !user.can_create? 
            return false
        end

        if user.provider.present? && user.is_social? && !social_service
            return false
        end

        return true 
    end

    def editable_by?(user)
        self.event_type.creable < 1 && editable?(user) && (author_id == user.id || (user.pon_id==self.pon_id && user.can_moderate?))
    end

    private
    
      def valid_date_ranges
        errors.add(:end_event, :invalid_date_range) if end_event && start_event && end_event < start_event
      end
 
      def event_slots_presence
        creable = EventType.where(id: event_type_id).first.creable
        if creable == 0
            if event_slots.length < 1
                errors.add(:all_day_event, :no_data_slot_found)         
            end
        end        
      end      
    
end
