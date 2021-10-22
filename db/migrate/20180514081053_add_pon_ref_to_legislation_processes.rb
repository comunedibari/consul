class AddPonRefToLegislationProcesses < ActiveRecord::Migration
  def change
    add_reference :legislation_processes, :pon, index: true, foreign_key: true, null: false
  end
end
