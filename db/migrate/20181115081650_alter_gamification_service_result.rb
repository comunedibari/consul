class AlterGamificationServiceResult < ActiveRecord::Migration
  def change
    rename_column :gamification_results, :month_stats, :prec_month_stats
    remove_column :gamification_results, :value
  end
end
