class CreateLegislationProcessChances < ActiveRecord::Migration
  def change
    create_table :legislation_process_chances do |t|
        t.belongs_to :legislation_process, index: true, foreign_key: true
        t.bigint :price
        t.string :financing
        t.string :work_status 
        t.string :benefit
        t.string :addressed_to
        t.string :purpose
    end
  end
end
