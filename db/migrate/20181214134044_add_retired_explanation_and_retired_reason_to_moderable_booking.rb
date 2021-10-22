class AddRetiredExplanationAndRetiredReasonToModerableBooking < ActiveRecord::Migration
  def change
    add_column :moderable_bookings, :retired_reason, :string, default: nil
    add_column :moderable_bookings, :retired_explanation, :text, default: nil
  end
end
