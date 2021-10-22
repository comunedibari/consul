class AddModerationFlagtoReportings < ActiveRecord::Migration
  def change
    add_column :reportings, :moderation_flag, :boolean, null: true
  end
end
