class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string   "title"
      t.text     "description"
      t.datetime :start_event
      t.datetime :end_event
      t.tsvector "tsv"

    end
    add_index :events, :tsv, using: "gin"

  end
end
