class AddContactsToLegislationProcessChances < ActiveRecord::Migration
  def change
    add_column :legislation_process_chances, :contacts, :string
  end
end
