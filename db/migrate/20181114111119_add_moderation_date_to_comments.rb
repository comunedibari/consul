class AddModerationDateToComments < ActiveRecord::Migration
  def up
    add_column :comments, :moderation_date, :datetime, defualt: nil
    add_index :comments, :moderation_date
  end

  def down
    remove_index :comments, :tsv
    remove_column :comments, :tsv
  end
end
