class UpdateColumnUserInvestmentStatus < ActiveRecord::Migration
  def up
    change_column :user_investments, :status, 'integer USING CAST(status AS integer)'
  end

  def down
    change_column :user_investments, :status, 'varchar(10) USING CAST(status AS varchar(10))'
  end
end
