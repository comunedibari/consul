class CrowdfundingNotification < ActiveRecord::Base
    include Graphqlable
    include Notifiable
  
    belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
    belongs_to :crowdfunding
  
    validates :title, presence: true
    validates :body, presence: true
    validates :crowdfunding, presence: true
    validate :minimum_interval
  
    scope :public_for_api, -> { where(crowdfunding_id: Crowdfunding.public_for_api.pluck(:id)) }
  
    def minimum_interval
      return true if crowdfunding.try(:notifications).blank?
      interval = Setting[:crowdfunding_notification_minimum_interval_in_days]
      minimum_interval = (Time.current - interval.to_i.days).to_datetime
      if crowdfunding.notifications.last.created_at > minimum_interval
        errors.add(:title, I18n.t('activerecord.errors.models.crowdfunding_notification.attributes.minimum_interval.invalid', interval: interval))
      end
    end
  
    def notifiable
      crowdfunding
    end
  
  end
  