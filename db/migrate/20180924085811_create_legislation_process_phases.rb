class CreateLegislationProcessPhases < ActiveRecord::Migration
  def change
    create_table :legislation_process_phases do |t|
      t.belongs_to :legislation_process, index: true, foreign_key: true      
      t.string :code
      t.string :description 
      t.bigint :idalice
      t.datetime :datainizioprevista
      t.datetime :datafineprevista
      t.datetime :datainizioeffettiva
      t.datetime :datafineeffettiva
    end
  end
end
