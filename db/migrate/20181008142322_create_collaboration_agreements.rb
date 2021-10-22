class CreateCollaborationAgreements < ActiveRecord::Migration
  def change
    create_table :collaboration_agreements do |t|
      
      t.string :title
      t.text :description
      t.text :summary
      t.text :additional_info
      t.date :start_date, index: true
      t.date :end_date, index: true
      t.date :debate_start_date, index: true
      t.date :debate_end_date, index: true
      t.boolean :debate_phase_enabled, default: false
      t.boolean :allegations_phase_enabled, default: false
      t.boolean :draft_publication_enabled, default: false
      t.boolean :result_publication_enabled, default: false
      t.date :proposals_phase_start_date, index: true
      t.date :proposals_phase_end_date, index: true
      t.boolean :proposals_phase_enabled, default: false
      t.text :proposals_description
      t.date :draft_publication_date, index: true
      t.date :allegations_start_date, index: true
      t.date :allegations_end_date, index: true
      t.date :result_publication_date, index: true
      t.tsvector :tsv

      t.datetime :hidden_at, index: true
      t.datetime :created_at, index: true
      t.datetime :update_at, index: true

      t.timestamps null: false
    end
  end
end
