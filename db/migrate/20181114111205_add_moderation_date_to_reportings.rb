class AddModerationDateToReportings < ActiveRecord::Migration
  def up
    add_column :reportings, :moderation_date, :datetime, defualt: nil
    add_index :reportings, :moderation_date
  end

  def down
    remove_index :reportings, :tsv
    remove_column :reportings, :tsv
  end
end
