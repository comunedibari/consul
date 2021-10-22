class SectorContent < ActiveRecord::Base

    include Sectorable

    belongs_to :sectorable, polymorphic: true
    belongs_to :sector, class_name: 'Sector', foreign_key: 'sector_id'







end