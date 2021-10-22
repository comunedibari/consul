class AddGeozoneRefToLegislationProcesses < ActiveRecord::Migration
  def change
    add_reference :legislation_processes, :geozone, index: true, foreign_key: true, null: true
  end
end
