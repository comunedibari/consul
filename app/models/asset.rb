class Asset < ActiveRecord::Base
  include Documentable
  include Imageable
  include Mappable
  include Searchable
  include Taggable
  include Filterable
  include Notifiable
  include Galleryable
  include Sociable

  
  include ActsAsParanoidAliases
  acts_as_paranoid column: :hidden_at
  
  acts_as_bookable time_type: :range, capacity_type: :closed, bookable_across_occurrences: true
  MAX_SLOTS_FOR_EVENT = 10

  documentable max_documents_allowed: 3,
               max_file_size: 3.megabytes#,
  #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
  #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")

  imageable max_images_allowed: 6

  validates :name, presence: true
  validates :address, presence: true
  validates :contacts, presence: true

  
  belongs_to :pon
  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  has_many :availabilities
  has_many :moderable_bookings, class_name: "BookingManager::ModerableBooking",  foreign_key: "bookable_id"

  scope :for_render,     -> { includes(:tags) }
  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :sort_by_oldest, -> { order(created_at: :asc) }
  scope :public_for_api, -> { all.mod_approved }
  scope :successful,     -> { where("cached_votes_up >= ?", Asset.votes_needed_for_success) }
  scope :unsuccessful,   -> { where("cached_votes_up < ?", Asset.votes_needed_for_success) }
  scope :by_user_pon,    -> { where(pon_id: User.pon_id)}
  scope :last_week,                -> { where("created_at >= ?", 7.days.ago)}

  def editable_by?(user)
   user.pon_id==self.pon_id && user.can_moderate?
  end

  def self.assets_orders(user)
    orders = %w{hot_score created_at end_date confidence_score past succesfull_crowd archival_date }
    #orders << "recommendations" if user.present?
    orders
  end  

  def self.recommendations(user)
    tagged_with(user.interests, any: true)
    .where("author_id != ?", user.id)
end

  def searchable_values
    { name              => 'A',
      author.username    => 'B',
      tag_list.join(' ') => 'B',
      description        => 'D',
    }
  end

  def self.search(terms)
    #by_code = search_by_code(terms.strip)
    #by_code.present? ? by_code : pg_search(terms)
    pg_search(terms)
  end

  def self.search_by_code(terms)
    matched_code = match_code(terms)
    results = where(id: matched_code[1]) if matched_code
    return results if results.present? && results.first.code == terms
  end

  #add taggs to events
  def self.for_summary
    summary = {}
    categories = ActsAsTaggableOn::Tag.category_names.sort
    groups = categories
    groups.each do |group|
    summary[group] = search(group).last_week.sort_by_confidence_score.limit(3)
    end
    summary
  end

  def self.recommendations(user)
    tagged_with(user.interests, any: true)
    .where("author_id != ?", user.id)
    .unsuccessful
    .not_followed_by_user(user)
    .not_supported_by_user(user)
  end

  #def to_param
  #  "#{id}-#{name}".parameterize
  #end

end
