class AddColumnHiddenAtToAgreementRequirements < ActiveRecord::Migration
  def change
    add_column :agreement_requirements, :hidden_at, :datetime
    add_index :agreement_requirements, :hidden_at
  end
end
