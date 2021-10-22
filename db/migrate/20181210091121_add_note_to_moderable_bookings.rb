class AddNoteToModerableBookings < ActiveRecord::Migration
  def up
    add_column :moderable_bookings, :note, :text
  end

  def down
    remove_column :moderable_bookings, :text
  end
end
