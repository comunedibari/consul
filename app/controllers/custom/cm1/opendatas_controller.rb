class OpendatasController < ApplicationController
  skip_authorization_check

  
  def index
    if current_user && current_user.administrator?
      @types=valid_types
      if User.pon_id == nil || User.pon_id == 0
        @pon_id = Rails.application.config.default_pon
      else
        @pon_id = User.pon_id 
      end
    else
      raise CanCan::AccessDenied
    end
  end

  def download_csv
    type = params[:type]
    pon_id = params[:pon_id]
    if type == "discussioni"
      @elements = Debate.public_for_api.where(pon_id: pon_id).order(:id)
    elsif type == "petizioni"
      @elements = Proposal.public_for_api.where(pon_id: pon_id).order(:id)
    elsif type == "lavori_pubblici"
      @elements = Legislation::ProcessWork.public_for_api.by_pon_id(pon_id).order(:id)
    elsif type == "opportunita"
      @elements = Legislation::ProcessChance.public_for_api.by_pon_id(pon_id).order(:id)    
    elsif type == "eventi"
      @elements = Event.public_for_api.where(pon_id: pon_id).order(:id)
    elsif type == "votazioni"
      @elements = Poll.public_for_api.where(pon_id: pon_id).order(:id)
    elsif type == "terzo_settore"
      @elements = Sector.public_for_api.order(:id)
    elsif type == "crowdfundings"
      @elements = Crowdfunding.public_for_api.where(pon_id: pon_id).order(:id)
    elsif type == "patti_di_collaborazione"
      @elements = Collaboration::Agreement.public_for_api.where(pon_id: pon_id).order(:id)
    end    

    respond_to do |format|
      format.html
      format.csv { send_data @elements.to_csv, filename: "#{type}-#{Date.today}.csv" }
    end
  end

  private

  def opendata_params
    params.require(:type)
  end

  def valid_types
    [
      "petizioni",
      "discussioni",
      "crowdfundings",
      "lavori_pubblici",
      "opportunita",
      "terzo_settore",
      "patti_di_collaborazione",
      "eventi",
      "votazioni"
    ]
  end

end
