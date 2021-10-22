class AddIndexGamificationServiceResult < ActiveRecord::Migration
  def change
    add_index(:gamification_service_results, [:user_id, :service], unique: true, name: "gsIndex")
  end
end
