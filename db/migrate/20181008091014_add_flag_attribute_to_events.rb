class AddFlagAttributeToEvents < ActiveRecord::Migration
  def change
    add_column :events, :flags_count,  :integer ,default: 0
    add_column :events, :ignored_flag_at,  :datetime 
    add_column :events, :moderation_flag, :boolean, null: true
  end
end
