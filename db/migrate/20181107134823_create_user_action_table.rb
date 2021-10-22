class CreateUserActionTable < ActiveRecord::Migration
  def change
    create_table :user_actions do |t|
      t.references :user, foreign_key: true, null:false
      t.references :gamification_score, foreign_key:true,null:false
      t.boolean :scheduled, default: false
      t.timestamp :created_at
      t.datetime :scheduled_at
    end
  end
end

