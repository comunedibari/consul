class AddModerationFlagToCrowdfundings < ActiveRecord::Migration
  def change
    add_column :crowdfundings, :moderation_flag, :boolean, null: true
  end
end
