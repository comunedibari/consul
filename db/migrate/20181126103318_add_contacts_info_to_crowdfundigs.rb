class AddContactsInfoToCrowdfundigs < ActiveRecord::Migration
  def change
    add_column :crowdfundings, :contacts_info, :text
  end
end
