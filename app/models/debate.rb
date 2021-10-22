require 'numeric'
class Debate < ActiveRecord::Base
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
  include Relationable
  include Notifiable
  include Imageable
  include Documentable
  include Mappable
  include Galleryable
  include Sectorable
  include Sociable
  include Moderable
 



  def self.to_csv
    CSV.generate(:col_sep => ";") do |csv|
      csv << %w{ id titolo descrizione data_creazione numero_commenti numero_voti_favorevoli numero_voti_sfavorevoli municipalità zona latitudine longitudine} 
      all.each do |e|
        csv << [
          e.id, 
          e.title, 
          e.description, 
          e.created_at.strftime('%Y-%m-%d %H:%M:%S'), 
          e.comments_count ? e.comments_count : "-", 
          e.cached_votes_up ? e.cached_votes_up : "-",
          e.cached_votes_down ? e.cached_votes_down : "-",
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
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
  imageable max_images_allowed: 3
  acts_as_votable
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases
  
  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  belongs_to :geozone
  belongs_to :pon
  has_many :comments, as: :commentable
  has_many :votes, as: :votable


  
  #validates :external_url, format: { with: /[ ,;]/, message: I18n.t('debates.debate.errors.notSavedLink') }  #modifica_mia
  #validates :title, presence: true
  #validates :description, presence: true
  validates :author, presence: true

  validates :title, length: { in: 4..Debate.title_max_length }
  validates :description, length: { in: 10..Debate.description_max_length }
 
  validates :terms_of_service, acceptance: { allow_nil: false }, on: :create

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
  scope :previous_month,           -> { where("created_at >= ?", (Time.current.beginning_of_month()-1.month)).where("created_at < ?", Time.current.beginning_of_month())}
  scope :current_month,            -> { where("created_at >= ?", Time.current.beginning_of_month())}
  scope :featured,                 -> { where("featured_at is not null")}
  scope :public_for_api,           -> { all.mod_approved }
  scope :by_user_pon,              -> { where(pon_id: User.pon_id)}

  
  
  # Ahoy setup
  visitable # Ahoy will automatically assign visit_id on create

  attr_accessor :link_required

  def url
    debate_path(self)
  end

  def self.recommendations(user)
    tagged_with(user.interests, any: true)
      .where("author_id != ?", user.id)
  end

  def searchable_values
    { title              => 'A',
      author.username    => 'B',
      tag_list.join(' ') => 'B',
      #geozone.try(:name) => 'B',
      description        => 'D',
    }
  end

  def self.search(terms)
    pg_search(terms)
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
    total_votes <= Setting['max_votes_for_debate_edit',user.pon_id].to_i
  end

  # def editable_by?(user)
  #   editable?(user) && (author_id == user.id || (user.pon_id==self.pon_id && user.can_moderate?))
  # end

  def creable_by?(user)
    # se sei un utente social e se il servizio è attivo per utenti social 

    social_service = Setting.where(key: 'service_social.debates').where("value = 'true' ").where(pon_id: user.pon_id).first
    
    if !user.can_create? 
      return false
    end
    if user.provider.present? && user.is_social? && !social_service #se sono social e non è attivo il servizio per i social
      return false
    end

    return true  #se sono spid oppure se cono social ed è attivo il servizio per i social
  
  end

  def editable_by?(user)  
      editable?(user) && (author_id == user.id || (user.pon_id==self.pon_id && user.can_moderate?))
  end

  def register_vote(user, vote_value)
    if votable_by?(user)
      Debate.increment_counter(:cached_anonymous_votes_total, id) if user.unverified? && !user.voted_for?(self)
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
    tags.each{ |t| t.decrement_custom_counter_for('Debate') }
  end

  def after_restore
    tags.each{ |t| t.increment_custom_counter_for('Debate') }
  end

  def featured?
    featured_at.present?
  end

  def self.debates_orders(user)
    orders = %w{hot_score confidence_score created_at relevance}
    orders << "recommendations" if user.present?
    orders
  end

  #add taggs to debates
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


  

      


  def geo_hot_score()
    count_comments_debate = self.comments.joins(:user).where("users.public_map = ?", TRUE).group(:user_id).count

    count_comments_debate.each do |elem|
      count_comments_debate[elem[0]] = elem[1]* Rails.application.config.new_comment
    end

    count_votes_debate = self.votes.where(voter_type: "User").joins(:user).where("users.public_map = ?", TRUE).group(:voter_id).count 

    count_votes_debate.each do |elem|
      count_votes_debate[elem[0]] = elem[1]*  Rails.application.config.poll_element
    end 

    count_votes_comments = self.comments.includes(:vote).where(:votes => {voter_type: "User"}).joins(:user).where("users.public_map = ?", TRUE).group(:voter_id).count

    count_votes_comments.each do |elem|
      count_votes_comments[elem[0]] = elem[1]* Rails.application.config.poll_comment
    end 


    totale = count_comments_debate.merge(count_votes_debate)
    totale = totale.merge(count_votes_comments)

    codes_and_totals = [count_comments_debate, count_votes_debate]#,count_votes_comments]

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
  
end
