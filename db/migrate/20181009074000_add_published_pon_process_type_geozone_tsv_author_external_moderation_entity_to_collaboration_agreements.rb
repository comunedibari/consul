class AddPublishedPonProcessTypeGeozoneTsvAuthorExternalModerationEntityToCollaborationAgreements < ActiveRecord::Migration
  def change

    add_column :collaboration_agreements, :published, :boolean, default: true
    add_column :collaboration_agreements, :process_type, :integer, default: 1
    add_column :collaboration_agreements, :author_id, :integer
    add_column :collaboration_agreements, :external_id, :integer, null: true
    add_column :collaboration_agreements, :moderation_entity, :integer, null: true
    
    add_reference :collaboration_agreements, :pon, index: true, foreign_key: true, null:false
    add_reference :collaboration_agreements, :geozone, index: true, foreign_key: true


  end
end
