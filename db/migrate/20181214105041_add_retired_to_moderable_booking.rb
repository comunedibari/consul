class AddRetiredToModerableBooking < ActiveRecord::Migration
  def change
    add_column :moderable_bookings, :retired_at, :datetime, default: nil
  end
end
