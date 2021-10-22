class CreateCrowdfundings < ActiveRecord::Migration
  def change
    create_table :crowdfundings do |t|
      t.string   "title", limit: 80
      t.text     "description"
      t.string   "question"
      t.string   "external_url"
      t.integer  "author_id"
      t.datetime "hidden_at"
      t.integer  "flags_count",      default: 0
      t.datetime "ignored_flag_at"
      t.integer  "cached_votes_up",  default: 0
      t.integer  "comments_count",   default: 0
      t.datetime "confirmed_hide_at"
      t.integer  "hot_score",        limit: 8, default: 0
      t.integer  "confidence_score", default: 0
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.belongs_to :geozone ,index: true, foreign_key: true


      t.tsvector   :tsv
      t.text      "summary", limit: 280
      t.datetime  "retired_at" ,default: nil
      t.belongs_to :pon ,index: true, foreign_key: true
      t.string    "video_url"
      t.belongs_to :community ,index: true, foreign_key: true
      t.string    "responsible_name", limit: 60
      t.belongs_to :annotation ,index: true, foreign_key: true
      t.string     "retired_reason", default: nil
      t.text       "retired_explanation", default: nil


    end

    add_index :crowdfundings, :tsv, using: "gin"

  end
end
