class CrowdfundingReward < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include Sociable

  validates :min_investment, presence: true
  validates :description, presence: true
  validate :validate_reward

  belongs_to :crowdfunding

  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases

  belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'


  def block
    hide
  end

  def creable_by?(user)
    # Vecchia logica: le ricompense potevano essere create da utenti non social
    # social_service = Setting.where(key: 'service_social.crowdfundings').where("value = 'true' ").where(pon_id: user.pon_id).first
    #
    # if !user.can_create?
    #     return false
    # end
    #
    #
    # if user.provider.present? && user.is_social? && !social_service && author_id != user.id
    #     return false
    # end
    #
    # return true

    # Nuova logica: le ricompense possono essere create da admin e moderatori dello stesso pon
    if User.pon_id == user.pon_id
      admin_or_mod_of_same_pon user
    else
      return false
    end
  end

  def editable_by?(user)
    # Le ricompense possono essere editate da admin e moderatori dello stesso pon
    admin_or_mod_of_same_pon user
  end

  private

  def admin_or_mod_of_same_pon(user)
    if user.moderator? or user.administrator?
      crowdfunding = Crowdfunding.where(id: self.crowdfunding_id).first
      crowdfunding.pon_id == user.pon_id
    else
      return false
    end
  end

  def validate_reward
    errors.add(:min_investment, :invalid_date_range) if !min_investment || min_investment < 0
  end


end
