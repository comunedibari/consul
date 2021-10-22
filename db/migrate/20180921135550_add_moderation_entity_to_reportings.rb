class AddModerationEntityToReportings < ActiveRecord::Migration
  def change
    add_column :reportings, :moderation_entity, :integer, null: true
  end
end
