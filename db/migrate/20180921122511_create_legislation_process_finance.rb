class CreateLegislationProcessFinance < ActiveRecord::Migration
  def change
    create_table :legislation_process_finances do |t|
        t.belongs_to :legislation_process, index: true, foreign_key: true
        t.string :id_finance
        t.string :code
        t.string :description
        t.string :amount
        t.string :action
        t.bigint :id_alice
        t.string :external_process_id
    end
  end
end