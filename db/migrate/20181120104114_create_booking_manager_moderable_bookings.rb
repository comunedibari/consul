class CreateBookingManagerModerableBookings < ActiveRecord::Migration
  def change
    create_table :moderable_bookings do |t|
      t.column :booking_id, :integer
      t.column :bookable_id, :integer
      t.column :booker_id, :integer
      t.column :time_start, :datetime
      t.column :time_end, :datetime
      t.column :hidden_at, :datetime
      t.column :moderation_entity, :integer
      t.timestamps null: false
    end
  end
end
