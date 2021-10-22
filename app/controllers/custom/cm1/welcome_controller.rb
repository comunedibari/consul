require 'net/http'
require 'json'

class WelcomeController < ApplicationController
  skip_authorization_check
  before_action :set_user_recommendations, only: :index, if: :current_user

  layout "devise", only: [:welcome, :verification]

  def index
  end

  def style
    if params[:agid] && params[:agid]== 'true'
      session[:portal_style] = 'agid';
    else
      session[:portal_style] = 'default';
    end
    respond_to do |format|
      format.html { render :text => 'Stile impostato: ' + session[:portal_style] }
    end
  end

  def welcome
  end

  def verification
    redirect_to verification_path if signed_in?
  end

  def services    
    @subheader_img = Setting.where(key: "sub_header.image").where(pon_id: User.pon_id).first
  end
  
  private

  def checkIfUserExist
  end

  def set_user_recommendations
    @recommended_debates = Debate.recommendations(current_user).sort_by_recommendations.limit(3)
    @recommended_proposals = Proposal.recommendations(current_user).sort_by_recommendations.limit(3)
    @recommended_crowdfundings = Crowdfunding.recommendations(current_user).sort_by_recommendations.limit(3)
    @recommended_reportings = Reporting.recommendations(current_user).sort_by_recommendations.limit(3)#miaaa

  end

end
