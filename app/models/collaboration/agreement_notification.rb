class Collaboration::AgreementNotification < ActiveRecord::Base
  include Graphqlable
  include Notifiable

  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
  belongs_to :collaboration_agreement, class_name: 'Collaboration::Agreement', foreign_key: 'collaboration_agreement_id'

  validates :title, presence: true
  validates :body, presence: true
  validates :collaboration_agreement, presence: true
  validate :minimum_interval

  scope :public_for_api, -> { where(collaboration_agreement_id: Collaboration::Agreement.public_for_api.pluck(:id)) }

  def minimum_interval
    return true if collaboration_agreement.try(:notifications).blank?
    interval = Setting[:proposal_notification_minimum_interval_in_days]
    minimum_interval = (Time.current - interval.to_i.days).to_datetime
    if collaboration_agreement.notifications.last.created_at > minimum_interval
      errors.add(:title, I18n.t('activerecord.errors.models.proposal_notification.attributes.minimum_interval.invalid', interval: interval))
    end
  end

  def notifiable
    collaboration_agreement
  end

end
