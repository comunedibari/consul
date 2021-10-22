class AddModerationDateToDebates < ActiveRecord::Migration
  def up
    add_column :debates, :moderation_date, :datetime, defualt: nil
    add_index :debates, :moderation_date
  end

  def down
    remove_index :debates, :tsv
    remove_column :debates, :tsv
  end
end
