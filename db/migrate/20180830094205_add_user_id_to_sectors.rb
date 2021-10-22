class AddUserIdToSectors < ActiveRecord::Migration
  def change
    add_reference :sectors, :user, index: true, foreign_key: true
  end
end
