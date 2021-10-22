class AddModerationEntityToCrowdfundings < ActiveRecord::Migration
  def change
    add_column :crowdfundings, :moderation_entity, :integer, null: true
  end
end
