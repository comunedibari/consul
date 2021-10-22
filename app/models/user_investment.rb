class UserInvestment < ActiveRecord::Base

  enum status: {pending: 0, accepted: 1, rejected: 2}

  include Rails.application.routes.url_helpers
  include Sociable

  # FORMAT_NO_CHECK_DIGIT = /([A-Z]{6})([\dL-V]{2})([ABCDEHLMPRST])([\dL-V]{2})([A-Z][\dL-V]{3})/
  # FORMAT = /#{FORMAT_NO_CHECK_DIGIT}([A-Z])/

  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  belongs_to :user
  belongs_to :crowdfunding
  attr_accessor :check

  validate :valid_value_investements
  validate :privacy_check

  validates :refound_info, presence: true, if: :is_refound_validation_needed
  validates :reward_info, presence: true, if: :is_reward_validation_needed

  validates :investor, presence: true
  validates :email, presence: true
  validates :fiscal_code, codice_fiscale: true

  # validate :cf_validate

  # validate :refund_validate
  # validate :rewards_validate

  scope :user_investments_accepted, -> { where("status =?", UserInvestment.statuses[:accepted]).count }

  def block
    hide
  end

  def valid_value_investements
    min_price_crowd = Crowdfunding.where(id: crowdfunding_id).first.min_price
    price_goal_crowd = Crowdfunding.where(id: crowdfunding_id).first.price_goal

    if value_investements? && (value_investements.to_f > 0) && (value_investements.to_f >= min_price_crowd.to_f)
      #ok
    else
      val_error = "Errore value_investements"
      errors.add(:value_investements, I18n.t('verification.residence.new.error_not_allowed_value_investements'))
    end
  end

  def crowd_author?
    crowdfunding = Crowdfunding.where(id: self.crowdfunding_id).first
    crowdfunding.present? && user == crowdfunding.author_id
  end

  def creable_by?(user)
    # se sei un utente social e se il servizio è attivo per utenti social
    #social_user = Identity.where("user_id =?",user.id)
    social_service = Setting.where(key: 'service_social.crowdfundings').where("value = 'true' ").where(pon_id: user.pon_id).first

    if !user.can_create?
      return false
    end

    if (user.provider.present? && user.is_social? && !social_service) || crowd_author?
      return false
    end

    return true
  end

  def self.creable_by_social?(crowdfunding_id)
    if crowdfunding_id
      crowdfunding = Crowdfunding.where(id: crowdfunding_id).first
      return crowdfunding.social_content.social_access?
    else
      true
    end
  end

  def is_refound_validation_needed
    crowdfunding = Crowdfunding.where(id: self.crowdfunding_id).first
    return crowdfunding.flag_refund
  end

  def is_reward_validation_needed
    crowdfunding = Crowdfunding.where(id: self.crowdfunding_id).first
    return crowdfunding.flag_rewards
  end

  private

  # def cf_is_valid?(str)
  #   return false unless str
  #   str.upcase!
  #   return false unless str =~ FORMAT
  #   true
  # end

  def cf_validate
    if !cf_is_valid?(fiscal_code)
      errors.add(:fiscal_code, I18n.t('verification.user_investment.error.fiscal_code'))
    end
  end

  # def refund_validate
  #   crowdfunding = Crowdfunding.where(id: self.crowdfunding_id).first
  #   if crowdfunding.flag_refund == true
  #     if self.refound_info == nil || self.refound_info == ""
  #       errors.add(:refound_info, I18n.t('verification.user_investment.error.refound_info'))
  #     end
  #   end
  # end
  #
  # def rewards_validate
  #   crowdfunding = Crowdfunding.where(id: self.crowdfunding_id).first
  #   if crowdfunding.flag_rewards == true
  #     if self.reward_info == nil || self.reward_info == ""
  #       errors.add(:reward_info, I18n.t('verification.user_investment.error.reward_info'))
  #     end
  #   end
  # end

  def privacy_check
    # if user == nil
    if check.to_i < 1
      errors.add(:check, I18n.t('crowdfundings.user_investments.form.privacy_check_mandatory'))
    end
    # end
  end

end
