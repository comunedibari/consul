class CreateEventTypes < ActiveRecord::Migration
  def change
    create_table :event_types do |t|
      t.string   "event_category"
    end
  end
end
