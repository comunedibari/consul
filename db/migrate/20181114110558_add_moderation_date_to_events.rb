class AddModerationDateToEvents < ActiveRecord::Migration
  
  def up
    add_column :events, :moderation_date, :datetime, defualt: nil
    add_index :events, :moderation_date
  end

  def down
    remove_index :events, :tsv
    remove_column :events, :tsv
  end

end
