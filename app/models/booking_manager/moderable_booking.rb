class BookingManager::ModerableBooking < ActiveRecord::Base

  include Sociable
  include Notifiable


  belongs_to :asset, -> { with_hidden }, class_name: 'Asset', foreign_key: 'bookable_id'
  belongs_to :user, -> { with_hidden }, class_name: 'User', foreign_key: 'booker_id'

  attr_accessor :data_f, :time_start_f, :time_end_f

  RETIRE_OPTIONS = %w(duplicated started unfeasible done other)

  validates :retired_reason, inclusion: { in: RETIRE_OPTIONS, allow_nil: true }

  # validates :data_f, presence: true
  # validates :time_start_f, presence: true
  # validates :time_end_f, presence: true

  scope :retired,                  -> { where.not(retired_at: nil) }
  scope :not_retired,              -> { where(retired_at: nil) }
  

  scope :sort_by_newest, -> { order(created_at: :desc) }
  #scope :sort_by_status, -> { where('status in (1)') }

  #scope :sort_by_to_be_approved,  -> { where('status in (2)') }
  scope :approved,   -> { where("status = 2") }
  scope :to_be_approved,   -> { where("status = 1") }
  scope :deleted,   -> { where("status = 3") }
  scope :by_user_pon,   -> { all } #Asset.joins(:moderable_bookings).where("assets.pon_id = ?",User.pon_id)}
  scope :by_bookable_id,    ->(bookable_id) { where(bookable_id: bookable_id) }
  scope :my_moderable_booking,   ->(user_booking_id) { where("booker_id =?", user_booking_id) }


=begin
  def self.book!(user, asset)
    start_ok = Date.today + 9.hours
    end_ok = start_ok + 1.hours
    val = user.book! asset, time_start: start_ok, time_end: end_ok
  end
  validates :time_start, presence:true
  validates :time_end, presence:true, if: :time_end > :time_start?

=end


def retired?
  retired_at.present?
end

#in corso
def pending?
  if status == 1
    true
  else
    false
  end    
end

#annullata
def deleted?
  if status == 3 
    true
  else
    false
  end    
end

#inserita
def accepted? 
  if status == 2
    true
  else
    false
  end    
end

def booking_status
  if accepted? 
    status = "Accettata"
  elsif pending?
    status = "In Corso"
  elsif deleted?
    status = "Cancellata"
  end
  status
end

def self.match_code(terms)
  /\A#{Setting["moderable_booking_code_prefix",User.pon_id]}-\d\d\d\d-\d\d-(\d*)\z/.match(terms)
end

def code
  "#{Setting['moderable_booking_code_prefix',User.pon_id]}-#{created_at.strftime('%Y-%m')}-#{id}"
end

def self.search(params)
  results = all
  results = results.by_bookable_id(params[:bookable_id]) if params[:bookable_id].present?
  results = results.pg_search(params[:search])   if params[:search].present?
  results
end

  def creable_by?(user)
    social_service = Setting.where(key: 'service_social.moderable_booking').where("value = 'true' ").where(pon_id: user.pon_id).first
    s = SocialContent.where(sociable_type: "Asset").where(sociable_id: bookable_id).first
    
    #if !user.can_create? 
    #  return false
    #end

    if user.provider.present? && user.is_social? && !social_service && s.social_access
      return false
    end

    # if social_service.value == "true" && s.social_access == false
    #   return false
    # end

    return true
      
  end

end
