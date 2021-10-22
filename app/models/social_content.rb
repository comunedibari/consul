class SocialContent < ActiveRecord::Base

    include Sociable

    belongs_to :sociable, polymorphic: true


end