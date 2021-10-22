class RenameModerationEntityToStatusInModerableBookings < ActiveRecord::Migration
  def change
    rename_column :moderable_bookings, :moderation_entity, :status
  end
end
