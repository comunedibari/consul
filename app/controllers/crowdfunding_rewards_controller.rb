class CrowdfundingRewardsController < ApplicationController
  include CustomUrlsHelper
  include FeatureFlags
  include FlagActions
  

  
 # before_action :authenticate_user!, only: :create
  before_action :load_data, only: [:show, :index]
  load_and_authorize_resource
  respond_to :html, :js
  before_action :verified_min_investment, only: [:create]

  def verified_min_investment
     @crowdfunding = Crowdfunding.where(id: crowdfunding_reward_params[:crowdfunding_id]).first
   end


  def create
    @crowdfunding_reward = CrowdfundingReward.new(crowdfunding_reward_params)     
    if @crowdfunding_reward.save
    else
      render :new
    end
  end

  def index 
  end

  private

    def crowdfunding_reward_params
      params.require(:crowdfunding_reward).permit(:min_investment,:description,:crowdfunding_id,:author_id,
      crowdfundings_attributes: [:id]
      )
    end

    def load_data
      @crowdfunding_reward = CrowdfundingReward.find(params[:id])
    end  
    
end
