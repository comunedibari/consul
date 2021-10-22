class AddAddressToLegislationProcessWorks < ActiveRecord::Migration
  def change
    add_column :legislation_process_works, :address, :string
  end
end
