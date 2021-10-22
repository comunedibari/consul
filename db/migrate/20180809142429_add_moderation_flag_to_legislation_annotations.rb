class AddModerationFlagToLegislationAnnotations < ActiveRecord::Migration
  def change
    add_column :legislation_annotations, :moderation_flag, :boolean, null: true
  end
end
