class AddProgressStatusToLegislationProcessChances < ActiveRecord::Migration
  def change
    add_column :legislation_process_chances, :progress_status, :string
  end
end
