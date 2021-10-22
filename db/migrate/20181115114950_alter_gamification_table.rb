class AlterGamificationTable < ActiveRecord::Migration
  def change
    rename_column :gamification_results,:global_stats,:total_stats
    add_column :gamification_results,:current_month_stats,:integer,:default => 0
    add_column :gamification_service_results,:total_result,:integer,:default => 0
    change_column :gamification_service_results, :prec_month_result,:integer,:default => 0

  end
end
