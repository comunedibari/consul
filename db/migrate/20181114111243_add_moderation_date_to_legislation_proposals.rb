class AddModerationDateToLegislationProposals < ActiveRecord::Migration
  def up
    add_column :legislation_proposals, :moderation_date, :datetime, defualt: nil
    add_index :legislation_proposals, :moderation_date
  end

  def down
    remove_index :legislation_proposals, :tsv
    remove_column :legislation_proposals, :tsv
  end
end
