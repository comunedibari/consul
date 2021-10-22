module CrowdfundingsHelper

  def author_of(crowdfunding)
    author_name = User.all.where(id: crowdfunding.author_id).first.username
  end

  def my_investments(crowdfunding)
    investments = UserInvestment.all.where(crowdfunding_id: crowdfunding.id).where(user_id: current_user.id).order(created_at: :desc)
  end

  # def number_userInvestors_by_crowdfunding(crowdfunding)
  #   UserInvestment.all.where(crowdfunding_id: crowdfunding.id).count
  # end

  # def totalInvestments_by_crowdfunding(crowdfunding)
  #   number_investors = number_userInvestors_by_crowdfunding(crowdfunding)
  #   total_investments = 0
  #   if number_investors != 0
  #     number_investors.each do |userInvestment|
  #       total_investments = total_investments + userInvestment.value_investements
  #     end
  #   end
  #   total_investments
  # end

  # def user_name_investment(user_investment)
  #   user = User.all.where(id: user_investment.user_id.to_i).first
  #   user.username
  # end

  def code(user_investment)
    code_investment = "#{Setting['crowdfunding_code_prefix', User.pon_id]}_#{user_investment.created_at.strftime('%Y-%m-%d')}_#{user_investment.id}"
  end

  def time_missing(crowdfunding)
    if crowdfunding.end_date? && crowdfunding.start_date?
      days_missing = (crowdfunding.end_date.to_date - Time.current.beginning_of_day.to_date).to_i
    end
  end

  def percentage_achieved(crowdfunding)
    if (crowdfunding.total_investiment != nil) && (crowdfunding.price_goal != nil)
      (crowdfunding.total_investiment / crowdfunding.price_goal) * 100
    end
  end

  def group_rewards(crowdfunding, reward)
    if reward.to_i == 80
      rewards_greater_80 = CrowdfundingReaward.all.where(crowdfunding_id: crowdfunding.id).where('min_investment >= 80').sample
    elsif reward.to_i == 60
      rewards_greater_60 = CrowdfundingReaward.all.where(crowdfunding_id: crowdfunding.id).where('min_investment >= 60').sample
    elsif reward.to_i == 40
      rewards_greater_40 = CrowdfundingReaward.all.where(crowdfunding_id: crowdfunding.id).where('min_investment >= 40').sample
    elsif reward.to_i == 20
      rewards_greater_20 = CrowdfundingReaward.all.where(crowdfunding_id: crowdfunding.id).where('min_investment >= 20').sample
    else
      rewards_greater_10 = CrowdfundingReaward.all.where(crowdfunding_id: crowdfunding.id).where('min_investment >= 10').sample
    end
  end

  def progress_bar_percentage(crowdfunding)
    case crowdfunding.cached_votes_up
    when 0 then
      0
    when 1..Crowdfunding.votes_needed_for_success then
      (crowdfunding.total_votes.to_f * 100 / Crowdfunding.votes_needed_for_success).floor
    else
      100
    end
  end

  def supports_percentage(crowdfunding)
    percentage = (crowdfunding.total_votes.to_f * 100 / Crowdfunding.votes_needed_for_success)
    case percentage
    when 0 then
      "0%"
    when 0..0.1 then
      "0.1%"
    when 0.1..100 then
      number_to_percentage(percentage, strip_insignificant_zeros: true, precision: 1)
    else
      "100%"
    end
  end

  def namespaced_crowdfunding_path(crowdfunding, options = {})
    @namespace_crowdfunding_path ||= namespace
    case @namespace_crowdfunding_path
    when "management"
      management_crowdfunding_path(crowdfunding, options)
    else
      crowdfunding_path(crowdfunding, options)
    end
  end

  def retire_crowdfundings_options
    Crowdfunding::RETIRE_OPTIONS.collect { |option| [t("crowdfundings.retire_options.#{option}"), option] }
  end

  def empty_recommended_crowdfundings_message_text(user)
    if user.interests.any?
      t('crowdfundings.index.recommendations.without_results')
    else
      t('crowdfundings.index.recommendations.without_interests')
    end
  end

  def author_of_crowdfunding?(crowdfunding)
    author_of?(crowdfunding, current_user)
  end

  def crowdfunding_current_editable?(crowdfunding)
    current_user && crowdfunding.editable_by?(current_user)
  end

  def current_moderable_comments?(crowdfunding)
    current_user && crowdfunding.moderable_comments_by?(current_user)
  end

  def crowdfundings_minimal_view_path
    crowdfundings_path(view: crowdfundings_secondary_view)
  end

  def crowdfundings_default_view?
    @view == "default"
  end

  def crowdfundings_current_view
    @view
  end

  def crowdfundings_secondary_view
    crowdfundings_current_view == "default" ? "minimal" : "default"
  end

  def status(crowdfunding)
    if crowdfunding.open? && (crowdfunding.not_retired?)
      t("admin.crowdfundings_admin.crowdfunding.status_open")
    elsif crowdfunding.next? && (crowdfunding.not_retired?)
      t("admin.crowdfundings_admin.crowdfunding.status_planned")
    elsif crowdfunding.past? || crowdfunding.retired?
      t("admin.crowdfundings_admin.crowdfunding.status_closed")
    end
  end

  def number_to_euro(amount)
    number_to_currency(amount, :unit => '€')
  end

  def investable_by_social(crowdfunding)
    if current_user&.is_social?
      crowdfunding.social_content.social_access?
    else
      true
    end
  end

end
