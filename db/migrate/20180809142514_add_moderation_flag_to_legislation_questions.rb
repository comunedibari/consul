class AddModerationFlagToLegislationQuestions < ActiveRecord::Migration
  def change
    add_column :legislation_questions, :moderation_flag, :boolean, null: true
  end
end
