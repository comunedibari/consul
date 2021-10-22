class AddModerationDateToProposals < ActiveRecord::Migration
  def up
    add_column :proposals, :moderation_date, :datetime, defualt: nil
    add_index :proposals, :moderation_date
  end

  def down
    remove_index :proposals, :tsv
    remove_column :proposals, :tsv
  end
end
