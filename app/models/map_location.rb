class MapLocation < ActiveRecord::Base

  belongs_to :localizable, polymorphic: true

  validates :longitude, :latitude, :zoom, presence: true, numericality: true

  def available?
    latitude.present? && longitude.present? && zoom.present?
  end

  def json_data
    {
      id: localizable_id ,
      type: localizable_type,
      lat: latitude,
      long: longitude
    }
  end

end
