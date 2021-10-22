class AddInfoToLegislationProcessChances < ActiveRecord::Migration
  def change
    add_column :legislation_process_chances, :info, :string
  end
end
