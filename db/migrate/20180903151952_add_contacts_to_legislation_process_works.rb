class AddContactsToLegislationProcessWorks < ActiveRecord::Migration
  def change
    add_column :legislation_process_works, :contacts, :string

  end
end
