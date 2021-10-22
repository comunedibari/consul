module Sociable
    extend ActiveSupport::Concern
    #attr_accessor :social_access  NOTA: social_content.social_access si chiama questo attr accessorio e non il campo sul DB
    included do
        has_one :social_content, as: :sociable, class_name: 'SocialContent', dependent: :destroy
    end

    module ClassMethods

        private
        def sociable(options = {})
        end    
    end

end