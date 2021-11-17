module AssetsHelper

  def asset_deleted(assed_id)
    Asset.where(id: assed_id).count > 0
  end

  def asset_current_editable?(asset)
     current_user && asset.editable_by?(current_user)
  end


  def author_of( asset)
      author_name = User.all.where(id: asset.author_id).first.username
  end


  def code(user_investment)
    code_investment = "#{Setting['asset_code_prefix',User.pon_id]}_#{user_investment.created_at.strftime('%Y-%m-%d')}_#{user_investment.id}"
  end


  def time_missing(asset)
    if asset.end_date? && asset.start_date?
      days_missing = (asset.end_date.to_date - Time.current.beginning_of_day.to_date).to_i
    end
  end

  def percentage_achieved(asset)
    if (asset.total_investiment != nil) && (asset.price_goal != nil)
      (asset.total_investiment / asset.price_goal) * 100
    end
  end

  def group_rewards(asset,reward)
    if reward.to_i == 80
      rewards_greater_80 = AssetReaward.all.where(asset_id: asset.id).where('min_investment >= 80').sample
    elsif reward.to_i == 60
      rewards_greater_60 = AssetReaward.all.where(asset_id: asset.id).where('min_investment >= 60').sample
    elsif reward.to_i == 40
      rewards_greater_40 = AssetReaward.all.where(asset_id: asset.id).where('min_investment >= 40').sample
    elsif reward.to_i == 20
      rewards_greater_20 = AssetReaward.all.where(asset_id: asset.id).where('min_investment >= 20').sample
    else
      rewards_greater_10 = AssetReaward.all.where(asset_id: asset.id).where('min_investment >= 10').sample
    end
  end

  def progress_bar_percentage(asset)
    case asset.cached_votes_up
    when 0 then 0
    when 1..Asset.votes_needed_for_success then (asset.total_votes.to_f * 100 / Asset.votes_needed_for_success).floor
    else 100
    end
  end

  def supports_percentage(asset)
    percentage = (asset.total_votes.to_f * 100 / Asset.votes_needed_for_success)
    case percentage
    when 0 then "0%"
    when 0..0.1 then "0.1%"
    when 0.1..100 then number_to_percentage(percentage, strip_insignificant_zeros: true, precision: 1)
    else "100%"
    end
  end

  def namespaced_asset_path(asset, options = {})
    @namespace_asset_path ||= namespace
    case @namespace_asset_path
    when "management"
      management_asset_path(asset, options)
    else
      asset_path(asset, options)
    end
  end

  def retire_assets_options
    Asset::RETIRE_OPTIONS.collect { |option| [ t("assets.retire_options.#{option}"), option ] }
  end

  def empty_recommended_assets_message_text(user)
    if user.interests.any?
      t('assets.index.recommendations.without_results')
    else
      t('assets.index.recommendations.without_interests')
    end
  end

  def author_of_asset?(asset)
    author_of?(asset, current_user)
  end

  def current_moderable_comments?(asset)
    current_user && asset.moderable_comments_by?(current_user)
  end
  

  def assets_minimal_view_path
    assets_path(view: assets_secondary_view)
  end

  def assets_default_view?
    @view == "default"
  end

  def assets_current_view
    @view
  end

  def assets_secondary_view
    assets_current_view == "default" ? "minimal" : "default"
  end


  def status(asset)
    if asset.open? && (asset.not_retired?) 
      t("admin.assets_admin.asset.status_open")
    elsif asset.next? && (asset.not_retired?)
      t("admin.assets_admin.asset.status_planned")
    elsif asset.past? || asset.retired?  
      t("admin.assets_admin.asset.status_closed")
    end
  end
    
  def count_resrvations_to_approve(asset)
    '['+asset.moderable_bookings.where(status: 1).count.to_s + ']'
  end

  def get_min_time asset_id  
    min = Day.joins(:availability).where("availabilities.asset_id= ?",asset_id).minimum("am_start")
    if !min
      min = Day.joins(:availability).where("availabilities.asset_id= ?",asset_id).minimum("pm_start")
    end
    !min ? "09:00:00": min.strftime("%H:%M:%S")

  end

  def get_max_time asset_id
    max = Day.joins(:availability).where("availabilities.asset_id= ?",asset_id).maximum("pm_end")
    if !max
      max = Day.joins(:availability).where("availabilities.asset_id= ?",asset_id).maximum("am_end")
    end    
    !max ? "20:00:00": max.strftime("%H:%M:%S")
  end

end
