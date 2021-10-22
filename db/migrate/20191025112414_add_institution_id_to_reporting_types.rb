class AddInstitutionIdToReportingTypes < ActiveRecord::Migration
  def up
    add_reference :reporting_types, :institution, index: true, foreign_key: true, null: true
  end

  def down
    remove_reference :reporting_types, :institution
  end
end