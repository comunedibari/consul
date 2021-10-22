class Notification < ActiveRecord::Base

  belongs_to :user, counter_cache: true
  belongs_to :notifiable, polymorphic: true

  validates :user, presence: true

  scope :read, -> { where.not(read_at: nil).recent.for_render }
  scope :unread, -> { where(read_at: nil).recent.for_render }
  scope :not_emailed, -> { where(emailed_at: nil) }
  scope :recent, -> { order(id: :desc) }
  scope :for_render, -> { includes(:notifiable) }

  delegate :notifiable_title, :notifiable_available?, :check_availability,
           :linkable_resource, to: :notifiable, allow_nil: true

  def mark_as_read
    update(read_at: Time.current)
  end

  def mark_as_unread
    update(read_at: nil)
  end

  def read?
    read_at.present?
  end

  def unread?
    read_at.nil?
  end

  def timestamp
    if notifiable.class.name == "Sector" or notifiable.class.name == 'JobLogs'
      notifiable.updated_at #utilzzo la data dell'ultima modifica
    else
      notifiable.created_at
    end
  end

  def filename
    if notifiable.class.name == 'JobLogs'
      notifiable.resource
    elsif notifiable.class.name == "Sector"
      notifiable.name
    else
      ""
    end
  end

  def self.add(user, notifiable)
    notification = Notification.existent(user, notifiable)
    if notification.present?
      increment_counter(:counter, notification.id)
    else
      create!(user: user, notifiable: notifiable)
    end
  end

  def self.existent(user, notifiable)
    unread.where(user: user, notifiable: notifiable).first
  end

  def notifiable_action
    case notifiable_type
    when "ProposalNotification"
      "proposal_notification"
    when "Collaboration::AgreementNotification"
      "collaboration_agreement_notification"
    when "CrowdfundingNotification"
      "crowdfunding_notification"
    when "ReportingNotification" #mia
      "reporting_notification"
    when "Comment"
      "replies_to"
    when "Collaboration::Agreement"
      "comments_on"
    when "Proposal"
      "comments_on"
    when "Crowdfunding"
      "comments_on"
    when "Debate"
      "comments_on"
    when "Legislation::Process"
      "interets_notification"
    when "Legislation::Question"
      "comments_on"
    when "Sector"
      "sector_update"
    when "StSector"
      "st_sector_notification"
    when "JobLogs"
      "job_xls_finished"
    when "Event"
      "event_notification"
    when "Asset"
      "asset_notification"
    when "BookingManager::ModerableBooking"
      "moderable_booking_notification"
    else
      "comments_on"
    end
  end

end
