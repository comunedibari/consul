class CreateUserInvestments < ActiveRecord::Migration
  def change
    create_table :user_investments do |t|

      t.belongs_to  :crowdfunding ,index: true, foreign_key: true
      t.belongs_to  :user ,index: true, foreign_key: true
      t.text        "note"
      t.datetime    "created_at", null: false
      t.integer     "value_investements"
    end
    
  end
end
