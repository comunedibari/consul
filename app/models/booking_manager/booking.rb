class BookingManager::Booking < ActiveRecord::Base
  self.table_name = "acts_as_bookable_bookings"

  def self.list(assetId)
    where(bookable_id:assetId)
  end



end
