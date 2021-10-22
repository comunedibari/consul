class AddModerationDateToProcesses < ActiveRecord::Migration
  def up
    add_column :legislation_processes, :moderation_date, :datetime, defualt: nil
    add_index :legislation_processes, :moderation_date
  end

  def down
    remove_index :legislation_processes, :tsv
    remove_column :legislation_processes, :tsv
  end
end
