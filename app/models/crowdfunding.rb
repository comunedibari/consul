class Crowdfunding < ActiveRecord::Base
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
  include Eventable
  include Sociable

  documentable max_documents_allowed: 3,
               max_file_size: 3.megabytes #,
  #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
  #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
  imageable max_images_allowed: 3
  include EmbedVideosHelper
  include Relationable

  acts_as_votable
  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  RETIRE_OPTIONS = %w(duplicated started unfeasible done other)

  has_many :crowdfunding_rewards
  has_many :user_investments


  belongs_to :pon
  scope :by_user_pon, -> { where(pon_id: User.pon_id) }
  scope :by_user, ->(user) { where(author: user).where('moderation_entity in (1,2)') }
  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  belongs_to :geozone
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :votes, as: :votable
  has_many :crowdfunding_notifications, dependent: :destroy
  has_many :user_investments

  #validates :images, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :valid_date_ranges
  validate :valid_value_min_price
  validate :valid_value_price_goal
  #validate  :valid_min_price
  #validates :title, presence: true
  #validates :fiscal_data, presence: true

  #validates :question, presence: true
  validates :summary, presence: true
  validates :author, presence: true
  validates :pon, presence: true
  #validates :responsible_name, presence: true

  validates :description, presence: true
  validates :title, length: {in: 4..Crowdfunding.title_max_length}
  validates :description, length: {maximum: Crowdfunding.description_max_length}
  #validates :question, length: { in: 10..Crowdfunding.question_max_length }
  #validates :responsible_name, length: { in: 6..Crowdfunding.responsible_name_max_length }
  #validates :retired_reason, inclusion: { in: RETIRE_OPTIONS, allow_nil: true }

  validates :terms_of_service, acceptance: {allow_nil: false}, on: :create

  validate :valid_video_url?

  before_validation :set_responsible_name

  before_save :calculate_hot_score


  scope :for_render, -> { includes(:tags) }
  scope :sort_by_hot_score, -> { opens.reorder(hot_score: :desc) }
  scope :sort_by_confidence_score, -> { where('total_investiment > 0').order(count_investors: :desc, total_investiment: :desc) }
  scope :sort_by_most_commented, -> { reorder(comments_count: :desc) }
  scope :sort_by_random, -> { reorder("RANDOM()") }
  scope :sort_by_relevance, -> { all }
  scope :sort_by_flags, -> { order(flags_count: :desc, updated_at: :desc) }
  scope :sort_by_archival_date, -> { archived.sort_by_confidence_score }

  # mia versione di archiviato(finito dal punto di vista temporale ,ma non è stato raggiunto il price_goal)

  # attivi in scadenza
  scope :sort_by_end_date, -> { opens.where("crowdfundings.end_date >= ?", Time.current.beginning_of_day).reorder(end_date: :asc) }

  # scaduti da più di (n) * mesi fa
  scope :archived, -> { where("crowdfundings.end_date < ?", Setting['months_to_archive_crowdfundings', User.pon_id].to_i.months.ago).reorder(end_date: :desc) }

  scope :sort_by_created_at, -> { opens.where("crowdfundings.created_at > ?", Time.current.beginning_of_day - 7.day).reorder(created_at: :desc) }


  #scope :sort_by_created_at,       -> { reorder(created_at: :desc) }
  #scope :sort_by_end_date,         -> { not_archived.not_retired.reorder(end_date: :asc) }
  #scope :archived,                 -> { where("crowdfundings.end_date < ?", Time.current.beginning_of_day ) }
  scope :sort_by_coming, -> { where("crowdfundings.start_date >= ?", (Time.current.beginning_of_day + 1.day).beginning_of_day).reorder(start_date: :asc) }
  scope :sort_by_succesfull_crowd, -> { where("crowdfundings.total_investiment >= crowdfundings.price_goal").opens.reorder(start_date: :asc) }
  scope :not_archived, -> { where("crowdfundings.end_date > ?", Setting['months_to_archive_crowdfundings', User.pon_id].to_i.months.ago) }
  scope :last_week, -> { where("crowdfundings.start_date >= ?", 7.days.ago) }
  scope :retired, -> { where.not(retired_at: nil) }
  scope :not_retired, -> { where(retired_at: nil) }
  scope :successful, -> { where("cached_votes_up >= ?", Crowdfunding.votes_needed_for_success) }
  scope :unsuccessful, -> { where("cached_votes_up < ?", Crowdfunding.votes_needed_for_success) }
  scope :public_for_api, -> { all.mod_approved }
  scope :not_supported_by_user, ->(user) { where.not(id: user.find_voted_items(votable_type: "Crowdfunding").compact.map(&:id)) }
  scope :by_pon, -> { where(pon_id: User.pon_id) }
  scope :opens, -> { where("start_date <= ? and end_date >= ?", Time.current.beginning_of_day, Time.current.beginning_of_day) }
  scope :next, -> { where("start_date > ?", Date.current).order('id DESC') }
  scope :sort_by_past, -> { where("end_date < ?", Date.current.beginning_of_day).order('id DESC') }
  scope :past, -> { sort_by_past }
  scope :waiting_moderation, -> { where("moderation_entity = 2").order('id DESC') }


  def self.to_csv
    CSV.generate(:col_sep => ";") do |csv|
      csv << %w{ id titolo descrizione data_creazione data_inizio data_fine numero_commenti numero_investimenti cifra_investita cifra_obiettivo municipio zona latitudine longitudine}
      all.each do |e|
        csv << [
            e.id,
            e.title,
            e.description,
            e.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            e.start_date.strftime('%Y-%m-%d %H:%M:%S'),
            e.end_date.strftime('%Y-%m-%d %H:%M:%S'),
            e.comments_count ? e.comments_count : "-",
            e.count_investors ? e.count_investors : "-",
            e.total_investiment ? e.total_investiment : "-",
            e.price_goal ? e.price_goal : "-",
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

  def close?
    end_date < Date.current
  end


  def past?
    end_date < Date.current
  end

  def next?
    start_date > Date.current
  end

  def self.current_id
    1
  end

  def url
    crowdfunding_path(self)
  end

  def url_new
    crowdfunding_path(self)
  end


  def self.not_followed_by_user(user)
    where.not(id: followed_by_user(user).pluck(:id))
  end

  def to_param
    "#{id}-#{title}".parameterize
  end

  def searchable_values
    {title => 'A',
     question => 'B',
     author.username => 'B',
     tag_list.join(' ') => 'B',
     #geozone.try(:name) => 'B',
     summary => 'C',
     #description        => 'D',
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
    /\A#{Setting["crowdfunding_code_prefix", User.pon_id]}-\d\d\d\d-\d\d-(\d*)\z/.match(terms)
  end

  def self.for_summary
    summary = {}
    categories = ActsAsTaggableOn::Tag.category_names.sort
    geozones = Geozone.by_user_pon.names.sort

    groups = categories + geozones
    groups.each do |group|
      summary[group] = search(group).last_week.sort_by_confidence_score.limit(3)
    end
    summary
  end


  def geo_hot_score()
    count_comments_crowdfunding = self.comments.joins(:user).where("users.public_map = ?", TRUE).group(:user_id).count

    count_comments_crowdfunding.each do |elem|
      count_comments_crowdfunding[elem[0]] = elem[1] * Rails.application.config.new_comment
    end

    count_votes_crowdfunding = self.votes.where(voter_type: "User").joins(:user).where("users.public_map = ?", TRUE).group(:voter_id).count

    count_votes_crowdfunding.each do |elem|
      count_votes_crowdfunding[elem[0]] = elem[1] * Rails.application.config.poll_element
    end

    count_votes_comments = self.comments.includes(:vote).where(:votes => {voter_type: "User"}).joins(:user).where("users.public_map = ?", TRUE).group(:voter_id).count

    count_votes_comments.each do |elem|
      count_votes_comments[elem[0]] = elem[1] * Rails.application.config.poll_comment
    end
    totale = count_comments_crowdfunding.merge(count_votes_crowdfunding)
    totale = totale.merge(count_votes_comments)

    codes_and_totals = [count_comments_crowdfunding, count_votes_crowdfunding, count_votes_comments]

    totals = codes_and_totals.reduce({}) do |sums, location|
      sums.merge(location) { |_, a, b| a + b }
    end

    heat_markers = Array.new
    heat_val = Array.new
    i = 0
    totals.each do |item|
      coords = MapLocation.where(localizable_type: "User").where(localizable_id: item[0]).pluck(:latitude, :longitude)
      if coords.length > 0
        coord = [coords[0][0], coords[0][1], item[1]]
        heat_val[i] = item[1]
        heat_markers[i] = Array.new(coord)
        i += 1
      end
    end

    if i >= Setting['min_interaction_for_heatmap', User.pon_id].to_i
      heat_markers.each do |item|
        if heat_val.max == heat_val.min
          val_norm = 100
        else
          val_norm = ((item[2] - heat_val.min) * 100 / (heat_val.max - heat_val.min))
        end
        item[2] = val_norm
      end
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
    total_votes <= Setting["max_votes_for_crowdfunding_edit", user.pon_id].to_i
  end


  def moderable_comments_by?(user)
    user && user.pon_id == self.pon_id && user.can_moderate?
  end

  def votable_by?(user)
    user && user.level_two_or_three_verified?
  end

  def retired?
    retired_at.present?
  end

  def not_retired?
    if retired_at == nil
      true
    else
      false
    end
  end


  #verifico se crowdfunding è traguardato
  def financed?
    self.total_investiment >= self.price_goal
  end

  def already_invest?(user)
    self.user_investments.where(status: UserInvestment.statuses[:accepted], user: user).exists?
  end

  def register_vote(user, vote_value)
    if votable_by?(user) && !archived?
      vote_by(voter: user, vote: vote_value)
    end
  end

  def code
    "#{Setting['crowdfunding_code_prefix', User.pon_id]}-#{created_at.strftime('%Y-%m')}-#{id}"
  end

  def after_commented
    save # updates the hot_score because there is a before_save
  end

  def calculate_hot_score
    self.hot_score = ScoreCalculator.hot_score_crowdfunding(start_date, end_date, total_investiment, count_investors, price_goal, min_price, comments_count)
  end

  def calculate_confidence_score
    self.confidence_score = ScoreCalculator.confidence_score_crowdfunding(count_investors, total_investiment, price_goal, min_price)
  end

  def after_hide
    tags.each { |t| t.decrement_custom_counter_for('Crowdfunding') }
  end

  def after_restore
    tags.each { |t| t.increment_custom_counter_for('Crowdfunding') }
  end

  def self.votes_needed_for_success
    Setting['votes_for_crowdfunding_success', User.pon_id].to_i
  end

  def successful?
    total_votes >= Crowdfunding.votes_needed_for_success
  end

  def archived?
    Time.current.beginning_of_day > end_date.beginning_of_day
  end

  def notifications
    crowdfunding_notifications
  end

  def users_to_notify
    (voters + followers).uniq
  end

  #qui trovo i filtri
  def self.crowdfundings_orders(user)
    orders = %w{hot_score created_at end_date confidence_score past succesfull_crowd archival_date }
    #orders << "recommendations" if user.present?
    orders
  end

  # def author_of(id_crowd)
  #   author_name = Users.where(id: self.author_id).first.username
  # end

  def exist_user_investments
    user_investments.exists?
  end


  #riprstina o nasconde l'evento associato all'oggetto
  def restore_event(flag)
    if self.event_content
      id = self.event_content.event_id
      event = Event.with_hidden.where(id: id).first
      event.hidden_at = flag ? nil : Time.current
      event.save
    end
  end

  def creable_by?(user)
    # social_service = Setting.where(key: 'service_social.crowdfundings').where("value = 'true' ").where(pon_id: user.pon_id).first
    #
    # if !user.can_create?
    #   return false
    # end
    # if user.provider.present? && user.is_social? && !social_service #se sono social e non è attivo il servizio per i social
    #   return false
    # end
    #
    # return true
    if User.pon_id == user.pon_id
      if user.administrator? or user.moderator?
        return true
      else
        return false
      end
    end
    return false
  end


  def editable_by?(user)
    # Logica vecchia: solo l'autore poteva editare
    # (author_id == user.id) && (self.user_investments.user_investments_accepted == 0)

    # Logica nuova: solo admin e moderatori dello stesso PON possono editare
    if (user.administrator? or user.moderator?) and self.user_investments.user_investments_accepted == 0
      user.pon_id == self.pon_id
    else
      return false
    end
  end

  protected

  def set_responsible_name
    if author && author.document_number?
      self.responsible_name = author.document_number
    end
  end


  private

  def valid_date_ranges
    errors.add(:end_date, :invalid_date_range) if end_date && start_date && end_date < start_date
  end

  def valid_value_min_price
    if (min_price.is_a? Numeric) && min_price.to_f > 0
      #ok
    else
      errors.add(:min_price, I18n.t('verification.residence.new.error_not_allowed_min_price'))
    end

  end

  def valid_value_price_goal
    if (price_goal.is_a? Numeric) && price_goal.to_f > 0
      #ok
    else
      errors.add(:price_goal, I18n.t('verification.residence.new.error_not_allowed_price_goal'))
    end

  end

  def valid_min_price
    if min_price.to_f < price_goal.to_f
      #ok
    else
      errors.add(:min_price, I18n.t('verification.residence.new.error_not_valid_min_price'))
    end
  end


end
