class CreateEventsNew < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string   "title"
      t.text     "description"
      t.datetime :start_event
      t.datetime :end_event
      t.tsvector "tsv"
      t.integer :author_id , null: true
      t.integer :moderation_entity , null: true
      t.integer :flags_count ,default: 0
      t.datetime :ignored_flag_at
      t.boolean :moderation_flag, null: true
      t.integer :comments_counts, default: 0
      t.integer :cached_votes_total, default: 0
      t.integer :cached_votes_up, default: 0
      t.integer :cached_votes_down, default: 0
      t.integer :cached_anonymous_votes_total, default: 0
      t.integer :cached_votes_score, default: 0
      t.integer :hot_score, limit: 8, default: 0
      t.integer :confidence_score, default: 0
      t.datetime :confirmed_hide_at
      t.datetime :hidden_at
      t.datetime :featured_at
      t.timestamps 
    end
    add_index :events, :tsv, using: "gin"
    add_reference :events, :event_type, index: true, foreign_key: true, null: true
    add_reference :events, :pon, index: true, foreign_key: true, null:false
  end
end
