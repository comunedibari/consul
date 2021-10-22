class Geozone < ActiveRecord::Base

  include Graphqlable

  has_many :proposals
  has_many :crowdfundings
  has_many :processes
  has_many :process_works
  has_many :process_chances
  has_many :spending_proposals
  has_many :debates
  has_many :users
  validates :name, presence: true
  scope :public_for_api, -> { all }
  belongs_to :pon
  scope :by_user_pon,              -> { where(pon_id: User.pon_id)}
  has_many :processes

  
  def self.names
    Geozone.pluck(:name)
  end

  def self.city
    where(name: 'city').first
  end

  def safe_to_destroy?
    Geozone.reflect_on_all_associations(:has_many).all? do |association|
      association.klass.where(geozone: self).empty?
    end
  end
end
