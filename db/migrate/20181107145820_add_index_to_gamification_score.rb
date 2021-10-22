class AddIndexToGamificationScore < ActiveRecord::Migration
  def change
    add_index(:gamification_scores,[:action_service, :action_type,:action_attribute], unique: true, name: "gIndex")
  end
end
