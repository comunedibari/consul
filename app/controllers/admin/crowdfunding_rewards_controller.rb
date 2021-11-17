class Admin::CrowdfundingRewardsController < Admin::BaseController

  include CustomUrlsHelper
  include FeatureFlags
  include FlagActions

  before_action :load_data, only: [:show, :index, :create]
  respond_to :html, :js

  def verify_administrator
    raise CanCan::AccessDenied unless current_user.present?
  end




  def create
    if ( crowdfunding_reward_params[:min_investment] == nil || crowdfunding_reward_params[:min_investment].to_f <= 0.0)
      flash[:error] =  I18n.t('verification.residence.new.error_not_allowed_crowdfunding_reward')
      redirect_to :back
      return
    elsif crowdfunding_reward_params[:min_investment].to_f < @crowdfunding.min_price.to_f
      flash[:error] =  I18n.t('verification.residence.new.error_crowdfunding_reward_too_low')
      redirect_to :back
      return
    #elsif @crowdfunding.crowdfunding_rewards.where(min_investment: crowdfunding_reward_params[:min_investment].to_f).count > 0
    #  flash[:error] =  I18n.t('verification.residence.new.error_crowdfunding_reward_already_present')
    #  redirect_to :back
    #  return
    elsif crowdfunding_reward_params[:description].to_s == '' || WYSIWYGSanitizer.new.sanitize_all(crowdfunding_reward_params[:description]).length < 10
      flash[:error] =  I18n.t('verification.residence.new.error_too_short_reward_description')
      redirect_to :back
      return
    end


    @crowdfunding_reward = CrowdfundingReward.new(crowdfunding_reward_params)
    if @crowdfunding_reward.save
      redirect_to rewards_admin_crowdfunding_path(@crowdfunding), notice: t("crowdfunding_rewards.form.notice" , value: @crowdfunding_reward.min_investment )
    else
      flash[:error] =  I18n.t('verification.residence.new.error_not_valid_reward')
      redirect_to :back
    end
  end


  def destroy
    @crowdfunding_reward = CrowdfundingReward.find(params[:id])
    @crowdfunding = Crowdfunding.where(id: @crowdfunding_reward.crowdfunding_id).first
    @crowdfunding_reward.destroy  #elimina logicamente per default dato ACTS as paranoid
    redirect_to rewards_admin_crowdfunding_path(@crowdfunding), notice: t("crowdfunding_rewards.form.reward_deleted")
  end


  private

    def crowdfunding_reward_params
      params.require(:crowdfunding_reward).permit(:min_investment,:description,:crowdfunding_id,
      crowdfundings_attributes: [:id]
      )
    end

    def load_data
      if crowdfunding_reward_params[:crowdfunding_id].present?
        @crowdfunding = Crowdfunding.where(id: crowdfunding_reward_params[:crowdfunding_id]).first
      end
      if crowdfunding_reward_params[:id].present?
        @crowdfunding_reward = CrowdfundingReward.find(params[:id])
      end
    end

end
