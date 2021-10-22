class AddEventToEventContents < ActiveRecord::Migration
  def change
    add_reference :event_contents, :event, index: true, foreign_key: true, null: true
  end
end
