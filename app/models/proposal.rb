class Proposal < ActiveRecord::Base
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
  include Communitable
  include Imageable
  include Mappable
  include Notifiable
  include Documentable
  include Galleryable
  include Sectorable
  include Moderable
  include Sociable


  def self.to_csv
    CSV.generate(:col_sep => ";") do |csv|
      csv << %w{ id titolo descrizione data_creazione numero_commenti numero_sostegni municipalità zona latitudine longitudine} 
      all.each do |e|
        csv << [
          e.id, 
          e.title, 
          e.description, 
          e.created_at.strftime('%Y-%m-%d %H:%M:%S'), 
          e.comments_count ? e.comments_count : "-", 
          e.cached_votes_up ? e.cached_votes_up : "-",
          e.pon.name,
          e.geozone ? e.geozone.name : nil,
          e.map_location ? e.map_location.latitude : nil, 
          e.map_location ? e.map_location.longitude : nil  
        ]
      end
    end
  end
  
  
  documentable max_documents_allowed: 3,
               max_file_size: 3.megabytes#,
               #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword","application/zip"],
               #extension_content_types: ["pdf","docx","doc","zip"] #Setting["extension_content_types",User.pon_id].split(",")
  imageable max_images_allowed: 3
  include EmbedVideosHelper
  include Relationable

  acts_as_votable
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  RETIRE_OPTIONS = %w(duplicated started unfeasible done other)

 
  belongs_to :pon
  scope :by_user_pon,              -> { where(pon_id: User.pon_id)}
  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  belongs_to :geozone
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :votes, as: :votable
  has_many :proposal_notifications, dependent: :destroy

  

  #validates :title, presence: true
  validates :question, presence: true
  validates :summary, presence: true
  validates :author, presence: true
  validates :pon, presence: true
  #validates :responsible_name, presence: true

  validates :title, length: { in: 4..Proposal.title_max_length }
  validates :description, length: { maximum: Proposal.description_max_length }
  validates :question, length: { in: 10..Proposal.question_max_length }
  #validates :responsible_name, length: { in: 6..Proposal.responsible_name_max_length }
  validates :retired_reason, inclusion: { in: RETIRE_OPTIONS, allow_nil: true }

  validates :terms_of_service, acceptance: { allow_nil: false }, on: :create

  validate :valid_video_url?

  before_validation :set_responsible_name

  before_save :calculate_hot_score, :calculate_confidence_score

  #scope :by_user_pon,            ->(query, topics_ids) { joins(:comments).where(query, topics_ids).uniq }
  #scope :by_user_pon,              -> {joins(:geozone).where("proposals.geozone_id is null") }
  #scope :by_user_pon,              -> {includes(:geozone).where("proposals.geozone_id is null") }
  #scope :by_user_pon,              -> {includes(:geozone).where("proposals.geozone_id is null") }
  #scope :by_user_pon,               joins(:geozone.where('geozone.id is not null')) 
  #scope :by_user_pon,              -> (user) { joins("LEFT JOIN geozones ON geozones.id = proposals.geozone_id")
  #                                      .where(" proposals.geozone_id is null or geozones.pon_id=?", user.pon_id ) }
  scope :for_render,               -> { includes(:tags) }
  scope :sort_by_hot_score,        -> { reorder(hot_score: :desc) }
  scope :sort_by_confidence_score, -> { reorder(confidence_score: :desc) }
  scope :sort_by_created_at,       -> { reorder(created_at: :desc) }
  scope :sort_by_most_commented,   -> { reorder(comments_count: :desc) }
  scope :sort_by_random,           -> { reorder("RANDOM()") }
  scope :sort_by_relevance,        -> { all }
  scope :sort_by_flags,            -> { order(flags_count: :desc, updated_at: :desc) }
  scope :sort_by_archival_date,    -> { archived.sort_by_confidence_score }
  scope :sort_by_recommendations,  -> { order(cached_votes_up: :desc) }
  scope :archived,                 -> { where("proposals.created_at <= ?", Setting["months_to_archive_proposals",User.pon_id].to_i.months.ago) }
  scope :not_archived,             -> { where("proposals.created_at > ?", Setting["months_to_archive_proposals",User.pon_id].to_i.months.ago) }
  scope :last_week,                -> { where("proposals.created_at >= ?", 7.days.ago)}
  scope :previous_month,           -> { where("created_at >= ?", (Time.current.beginning_of_month()-1.month)).where("created_at < ?", Time.current.beginning_of_month()) }
  scope :current_month,            -> { where("created_at >= ?", Time.current.beginning_of_month())}
  scope :retired,                  -> { where.not(retired_at: nil) }
  scope :not_retired,              -> { where(retired_at: nil) }
  scope :successful,               -> { where("cached_votes_up >= ?", Proposal.votes_needed_for_success) }
  scope :unsuccessful,             -> { where("cached_votes_up < ?", Proposal.votes_needed_for_success) }
  scope :public_for_api,           -> { all.mod_approved }
  scope :not_supported_by_user,    ->(user) { where.not(id: user.find_voted_items(votable_type: "Proposal").compact.map(&:id)) }
  scope :by_pon,                   -> {where(pon_id: User.pon_id) }


  def self.current_id
    1
  end

  def url
    proposal_path(self)
  end

  def url_new
    proposal_path(self)
  end

  def self.recommendations(user)
    tagged_with(user.interests, any: true)
      .where("author_id != ?", user.id)
      .unsuccessful
      .not_followed_by_user(user)
      .not_archived
      .not_supported_by_user(user)
  end

  def self.not_followed_by_user(user)
    where.not(id: followed_by_user(user).pluck(:id))
  end

  def to_param
    "#{id}-#{title}".parameterize
  end

  def searchable_values
    { title              => 'A',
      question           => 'B',
      author.username    => 'B',
      tag_list.join(' ') => 'B',
      #geozone.try(:name) => 'B',
      summary            => 'C',
      description        => 'D',
    }
  end

  def self.search(terms)
    by_code = search_by_code(terms.strip)
    by_code.present? ? by_code : pg_search(terms)
  end

  def self.search_by_code(terms)
    matched_code = match_code(terms)
    results = where(id: matched_code[1]) if matched_code
    return results if results.present? && results.first.code == terms
  end

  def self.match_code(terms)
    /\A#{Setting["proposal_code_prefix",User.pon_id]}-\d\d\d\d-\d\d-(\d*)\z/.match(terms)
  end

  def self.for_summary
    summary = {}
    categories = ActsAsTaggableOn::Tag.category_names.sort
    geozones   = Geozone.by_user_pon.names.sort

    groups = categories + geozones
    groups.each do |group|
      summary[group] = search(group).last_week.sort_by_confidence_score.limit(3)
    end
    summary
  end


  def geo_hot_score()
    count_comments_proposal = self.comments.joins(:user).where("users.public_map = ?", TRUE).group(:user_id).count

    count_comments_proposal.each do |elem|
      count_comments_proposal[elem[0]] = elem[1]* Rails.application.config.new_comment
    end

    count_votes_proposal = self.votes.where(voter_type: "User").joins(:user).where("users.public_map = ?", TRUE).group(:voter_id).count 
    
    count_votes_proposal.each do |elem|
      count_votes_proposal[elem[0]] = elem[1]*  Rails.application.config.poll_element
    end 
    
    count_votes_comments = self.comments.includes(:vote).where(:votes => {voter_type: "User"}).joins(:user).where("users.public_map = ?", TRUE).group(:voter_id).count

    count_votes_comments.each do |elem|
      count_votes_comments[elem[0]] = elem[1]* Rails.application.config.poll_comment
    end     
    totale = count_comments_proposal.merge(count_votes_proposal)
    totale = totale.merge(count_votes_comments)

    codes_and_totals = [count_comments_proposal, count_votes_proposal,count_votes_comments]

    totals = codes_and_totals.reduce({}) do |sums, location|
      sums.merge(location) { |_, a, b| a + b }
    end
    
    heat_markers = Array.new
    heat_val = Array.new
    i=0
    totals.each do |item| 
      coords = MapLocation.where(localizable_type: "User").where(localizable_id: item[0]).pluck(:latitude, :longitude)
      if coords.length > 0
        #massimo peso di un item: 50
        #item[1] = item[1] > 50 ? 50 : item[1] 

        coord = [coords[0][0],coords[0][1],item[1]]
        heat_val[i] = item[1]
        heat_markers[i] = Array.new(coord)
        i+=1
      end
    end

=begin
    logger.debug "\n\nstats totals--------------------------------\n"
    logger.debug totals
    logger.debug "\n\nstats val--------------------------------\n"
    logger.debug heat_val
    logger.debug "\n\nstats norm--------------------------------\n"
=end
    if i >= Setting['min_interaction_for_heatmap',User.pon_id].to_i
      heat_markers.each do |item| 
        if heat_val.max == heat_val.min
          val_norm = 100
        else
          val_norm = ((item[2]-heat_val.min)*100/(heat_val.max-heat_val.min))
        end
        item[2]=val_norm
        #logger.debug val_norm
      end
      #logger.debug "\n\nstats norm--------------------------------\n"
      #logger.debug heat_markers
    else
      heat_markers = Array.new
    end
    heat_markers

  end  

  def total_votes
    cached_votes_up
  end

  def voters
    User.active.where(id: votes_for.voters)
  end

  def editable?(user)
    total_votes <= Setting["max_votes_for_proposal_edit",User.pon_id].to_i
  end

  def moderable_comments_by?(user)
    user && user.pon_id==self.pon_id && user.can_moderate?
  end

  def votable_by?(user)
    user && user.level_two_or_three_verified?
  end

  def retired?
    retired_at.present?
  end



  def register_vote(user, vote_value)
    if votable_by?(user) && !archived?
      vote_by(voter: user, vote: vote_value)
    end
  end

  def code
    "#{Setting['proposal_code_prefix',User.pon_id]}-#{created_at.strftime('%Y-%m')}-#{id}"
  end

  def after_commented
    save # updates the hot_score because there is a before_save
  end

  def calculate_hot_score
    self.hot_score = ScoreCalculator.hot_score(created_at,
                                               total_votes,
                                               total_votes,
                                               comments_count)
  end

  def calculate_confidence_score
    self.confidence_score = ScoreCalculator.confidence_score(total_votes, total_votes)
  end

  def after_hide
    tags.each{ |t| t.decrement_custom_counter_for('Proposal') }
  end

  def after_restore
    tags.each{ |t| t.increment_custom_counter_for('Proposal') }
  end

  def self.votes_needed_for_success
    Setting['votes_for_proposal_success',User.pon_id].to_i
  end

  def successful?
    total_votes >= Proposal.votes_needed_for_success
  end

  def archived?
    created_at <= Setting["months_to_archive_proposals",User.pon_id].to_i.months.ago
  end

  def notifications
    proposal_notifications
  end

  def users_to_notify
    (voters + followers).uniq
  end

  def self.proposals_orders(user)
    orders = %w{hot_score confidence_score created_at relevance archival_date}
    orders << "recommendations" if user.present?
    orders
  end

  def creable_by?(user)
    social_service = Setting.where(key: 'service_social.proposals').where("value = 'true' ").where(pon_id: user.pon_id).first
    
    if !user.can_create? 
      return false
    end

    if user.provider.present? && user.is_social? && !social_service
      return false
    end

    return true 
  end

  def editable_by?(user)   
      editable?(user) && (author_id == user.id || (user.pon_id==self.pon_id && user.can_moderate?))
  end

  protected

    def set_responsible_name
      if author && author.document_number?
        self.responsible_name = author.document_number
      end
    end

end
