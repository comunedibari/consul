class Collaboration::Subscription < ActiveRecord::Base

    belongs_to :agreement, class_name: 'Collaboration::Agreement', foreign_key: 'collaboration_agreement_id'
    #belongs_to :geozone
    include Documentable
    include Imageable
    include Sociable


    belongs_to :user
    scope :is_not_subscription, -> { Collaboration::Subscription.where("user_id != ?", @current_user).order('id DESC') }
    


    documentable max_documents_allowed: 20,
              max_file_size: 3.megabytes#,
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")

    def author_id
        user_id
    end


    def creable_by?(user)
        social_service = Setting.where(key: 'service_social.collaboration').where("value = 'true' ").where(pon_id: user.pon_id).first
    
        if !user.can_create? 
            return false
        end

        if (user.provider.present? && user.is_social? && !social_service) || user.administrator?
            return false
        end

        return true
          
    end

    def readable_by?(user)
      (
      (author_id == user.id) || user.administrator? || user.moderator?
      )
    end
            
end