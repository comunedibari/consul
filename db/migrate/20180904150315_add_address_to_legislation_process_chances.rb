class AddAddressToLegislationProcessChances < ActiveRecord::Migration
  def change
    add_column :legislation_process_chances, :address, :string

  end
end
