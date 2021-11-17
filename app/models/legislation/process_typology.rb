class Legislation::ProcessTypology < ActiveRecord::Base
  has_many :process, class_name: 'Legislation::Process'

  validates :name, presence: true, :uniqueness => {:case_sensitive => false}


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

end
