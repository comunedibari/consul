class CreateLegislationProcessSgap < ActiveRecord::Migration
  def change
    create_table :legislation_process_sgaps do |t|
      t.belongs_to :legislation_process, index: true, foreign_key: true      
      t.boolean :progettosospeso
      t.float :importofinanziato 
      t.float :importobaseasta
      t.float :importorealizzato
      t.float :importodarealizzare
      t.datetime :inizioprogetto
      t.datetime :fineprogetto
      t.float :importosal
    end
  end
end
