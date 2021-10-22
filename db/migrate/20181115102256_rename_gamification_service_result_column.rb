class RenameGamificationServiceResultColumn < ActiveRecord::Migration
  def change
    rename_column :gamification_service_results, :global_partial_result, :current_month_result
    rename_column :gamification_service_results, :month_partial_result, :prec_month_result

  end
end
