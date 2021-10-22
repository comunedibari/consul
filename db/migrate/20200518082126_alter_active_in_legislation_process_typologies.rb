class AlterActiveInLegislationProcessTypologies < ActiveRecord::Migration
  def up
    change_column :legislation_process_typologies, :active, :boolean, :default => true
  end

  def down
    change_column :legislation_process_typologies, :active, :boolean, :default => false
  end
end
