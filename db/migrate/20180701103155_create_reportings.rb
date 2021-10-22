class CreateReportings < ActiveRecord::Migration
  def change
    create_table :reportings do |t|
      t.string   "title", limit: 80
      t.text     "description"
      t.string   "question"
      t.string   "external_url"
      t.integer  "author_id"
      t.string   "address", limit: 80
      t.string :description_status 
      t.datetime "date",   default: nil
      t.string :status_start_date
      t.integer :lat
      t.integer :lon
      t.text :note
      t.references :reporting_type, index: true, foreign_key: true, null:false
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
      t.string  "responsible_name",   limit: 60
      t.text "summary", limit: 280 
      t.string "video_url"
      #t.integer "physical_votes",   default: 0
      t.tsvector   :tsv
      t.integer "geozone_id",   default: nil, index: true 
      t.datetime "retired_at",   default: nil
      t.string "retired_reason",   default: nil
      t.text "retired_explanation",   default: nil
      t.references :community, index: true, foreign_key: true, null:false
      t.references :pon, index: true, foreign_key: true, null:false


      

    end
  end


end
