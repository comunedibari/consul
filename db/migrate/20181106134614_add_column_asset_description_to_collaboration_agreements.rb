class AddColumnAssetDescriptionToCollaborationAgreements < ActiveRecord::Migration
  def change
    add_column :collaboration_agreements, :asset_description, :text
  end
end
