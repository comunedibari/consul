class AddTsvToLegislationProcesses < ActiveRecord::Migration

  def up
    add_column :legislation_processes, :tsv, :tsvector
    add_index :legislation_processes, :tsv, using: "gin"
  end

  def down
    remove_index :legislation_processes, :tsv
    remove_column :legislation_processes, :tsv
  end

end