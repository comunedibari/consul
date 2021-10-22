class FixColumnNameProcessTypeToAgreementType < ActiveRecord::Migration
  def change
    rename_column :collaboration_agreements, :process_type, :agreement_type
  end
end
