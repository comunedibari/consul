class RemoveWorkStatusToLegislationProcessChances < ActiveRecord::Migration
  def change
    remove_column :legislation_process_chances, :work_status, :string
  end
end
