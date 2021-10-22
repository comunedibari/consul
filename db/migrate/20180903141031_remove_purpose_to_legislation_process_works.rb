class RemovePurposeToLegislationProcessWorks < ActiveRecord::Migration
  def change
    remove_column :legislation_process_works, :purpose, :string

  end
end
