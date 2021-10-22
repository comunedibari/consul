class AddSourceToUserInvestments < ActiveRecord::Migration
  def up
    add_column :user_investments, :source, :text
    UserInvestment.update_all ["source = 'Bari Partecipa'"]
  end

  def down
    remove_column :user_investments, :source
  end
end
