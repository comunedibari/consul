class AddModerationEntityToProcesses < ActiveRecord::Migration
  def change
    add_column :legislation_processes, :moderation_entity, :integer, null: true
  end
end
