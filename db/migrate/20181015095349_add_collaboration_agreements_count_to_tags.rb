class AddCollaborationAgreementsCountToTags < ActiveRecord::Migration
  def change
    add_column :tags, "collaboration/agreements_count", :integer, default: 0
    add_index :tags, "collaboration/agreements_count"
  end
end
