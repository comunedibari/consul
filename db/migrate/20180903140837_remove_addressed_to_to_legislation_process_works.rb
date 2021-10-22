class RemoveAddressedToToLegislationProcessWorks < ActiveRecord::Migration
  def change
    remove_column :legislation_process_works, :addressed_to, :string

  end
end
