class DebateNotification < ActiveRecord::Base
  include Graphqlable
  include Notifiable

  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  belongs_to :debate

  validates :title, presence: true
  validates :body, presence: true
  validates :debate, presence: true
  validate :minimum_interval

  scope :public_for_api, -> { where(debate_id: Debate.public_for_api.pluck(:id)) }

  def minimum_interval
    return true if debate.try(:notifications).blank?
    interval = Setting[:debate_notification_minimum_interval_in_days]
    minimum_interval = (Time.current - interval.to_i.days).to_datetime
    if debate.notifications.last.created_at > minimum_interval
      errors.add(:title, I18n.t('activerecord.errors.models.proposal_notification.attributes.minimum_interval.invalid', interval: interval))
    end
  end

  def notifiable
    debate
  end

end
