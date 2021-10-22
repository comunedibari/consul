class AddEventTypesToEvents < ActiveRecord::Migration
  def change
    add_reference :events, :event_type, index: true, foreign_key: true, null: true
  end
end
