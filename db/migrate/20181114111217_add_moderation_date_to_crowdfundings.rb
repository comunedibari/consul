class AddModerationDateToCrowdfundings < ActiveRecord::Migration
  def up
    add_column :crowdfundings, :moderation_date, :datetime, defualt: nil
    add_index :crowdfundings, :moderation_date
  end

  def down
    remove_index :crowdfundings, :tsv
    remove_column :crowdfundings, :tsv
  end
end
