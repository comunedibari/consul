class Pon < ActiveRecord::Base

    include Graphqlable
    self.table_name = "pons"


    has_many :geozones
    has_many :tags
    has_many :proposals
    has_many :crowdfundings
    has_many :reportings          #mia

    has_many :st_sectors
    has_many :sectors

    scope :list, -> { where('id IS NOT NULL') }
    scope :public_for_api, -> { all }
end
