class AddModerationDateToUsers < ActiveRecord::Migration
  def up
    add_column :users, :moderation_date, :datetime, defualt: nil
    add_index :users, :moderation_date
  end

  def down
    remove_index :users, :tsv
    remove_column :users, :tsv
  end
end
