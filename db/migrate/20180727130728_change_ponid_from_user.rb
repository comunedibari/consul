class ChangePonidFromUser < ActiveRecord::Migration

    def up
      change_column :users, :pon_id, :integer, null: true, :default => 0
    end

    def down
      change_column :users, :pon_id, :integer, null: false
      change_column_default(:users, :pon_id, nil)
    end    
end
