module Sectorable
    extend ActiveSupport::Concern
    attr_accessor :as_rappr_legale, :sector_id

    included do
        has_one :sector_content, as: :sectorable, class_name: 'SectorContent', dependent: :destroy
    end

    module ClassMethods

        private
        def sectorable(options = {})
        end    
    end

end