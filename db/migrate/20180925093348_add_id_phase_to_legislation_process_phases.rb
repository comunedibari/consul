class AddIdPhaseToLegislationProcessPhases < ActiveRecord::Migration
  def change
    add_column :legislation_process_phases, :id_phase, :integer, null: true
  end
end
