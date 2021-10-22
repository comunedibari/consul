class GamificationResult < ActiveRecord::Base
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  has_many :gamification_service_result



  #scope :sort_by_global_results, -> {where("current_month_stats >= 0") }
  #scope :reoder_sort_by_global_results, -> {reorder(current_month_stats: :desc).limit(10)}




  scope :sort_by_current_month, -> { where("current_month_stats > 0").reorder(current_month_stats: :desc) }
  scope :sort_by_prec_month,    -> { where("prec_month_stats > 0").reorder(prec_month_stats: :desc) }
  scope :sort_by_total,         -> { where("total_stats > 0").reorder(total_stats: :desc) }





  def self.gamifications_orders(user)
    orders = %w{ current_month prec_month total }
    orders
  end


  def self.update_stats(id)
    result = GamificationResult.find(id)
    result.update_attribute(:prec_month_stats,result.current_month_stats)
    result.update_attribute(:current_month_stats, 0 )

  end
end
