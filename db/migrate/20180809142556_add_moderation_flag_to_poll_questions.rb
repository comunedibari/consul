class AddModerationFlagToPollQuestions < ActiveRecord::Migration
  def change
    add_column :poll_questions, :moderation_flag, :boolean, null: true
  end
end
