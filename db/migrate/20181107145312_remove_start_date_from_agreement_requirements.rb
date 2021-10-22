class RemoveStartDateFromAgreementRequirements < ActiveRecord::Migration
  def change
    remove_column :agreement_requirements, :start_date
  end
end
