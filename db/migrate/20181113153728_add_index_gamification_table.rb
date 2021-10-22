class AddIndexGamificationTable < ActiveRecord::Migration
  def change
    add_index(:gamification_results, :user_id, unique: true, name: "resIndex")
    add_index(:gamification_service_results, [:gamification_result_id, :service], unique: true, name: "serviceResultIndex")

  end
end
