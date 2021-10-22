class CreateGamificationScore < ActiveRecord::Migration
  def change
    create_table :gamification_scores do |t|
      t.string :action_service
      t.string :action_type
      t.string :action_attribute
      t.string :description
      t.integer :value,default: 0
    end
  end
end
