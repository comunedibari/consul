class AddDefaultValueToGamificationRules < ActiveRecord::Migration
  def change
    change_column :gamification_service_results, :current_month_result,:integer,:default => 0
    change_column :gamification_results, :prec_month_stats,:integer,:default => 0
    change_column :gamification_results, :global_stats,:integer,:default => 0

  end
end
