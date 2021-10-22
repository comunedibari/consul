class GamificationsController < ApplicationController
  include ServiceFlags
  include SettingsHelper

  service_flag :gamification


  skip_authorization_check
  load_and_authorize_resource :gamification


  before_action :load_data, only: [:show, :index, :user]

  respond_to :html, :js

 
  #has_filters %w{ gamification_stats}
  has_orders ->(c) { GamificationResult.gamifications_orders(c.current_user) }, only: :index



  

  def show
  end


  def index 
    @current_order
    @global_stats = GamificationResult.all.send("sort_by_#{@current_order}")
    
    @service_stats  = {}
    if service?(:debates)
      @debates_stats = GamificationServiceResult.all.send("sort_by_#{@current_order}", "Debate" )
      if @debates_stats != nil && @debates_stats != []
        @service_stats.store("Debate" , @debates_stats)
      end
    end  
    if service?(:proposals)
      @proposals_stats = GamificationServiceResult.all.send("sort_by_#{@current_order}", "Proposal" )
      if @proposals_stats != nil && @proposals_stats != []
        @service_stats.store("Proposal" , @proposals_stats)
      end
    end

    if service?(:polls)
      @polls_stats = GamificationServiceResult.all.send("sort_by_#{@current_order}", "Poll" )
      if @polls_stats != nil && @polls_stats != []
        @service_stats.store("Poll" , @polls_stats)
      end
    end  
    if service?(:crowdfundings)
      @crowdfundings_stats = GamificationServiceResult.all.send("sort_by_#{@current_order}", "Crowdfunding" )
      if @crowdfundings_stats != nil && @crowdfundings_stats != []
         @service_stats.store("Crowdfunding" , @crowdfundings_stats)
      end
    end
    if service?(:events)
      @events_stats = GamificationServiceResult.all.send("sort_by_#{@current_order}", "Event" )
      if @events_stats != nil && @events_stats != []
        @service_stats.store("Event" , @events_stats)
      end
    end 
    if service?(:processes)
      @processes_stats = GamificationServiceResult.all.send("sort_by_#{@current_order}", "Legislation::Proposal" )
      if @processes_stats != nil && @processes_stats != []
        @service_stats.store("Legislation::Proposal" , @processes_stats)
      end
    end 
    if service?(:collaboration)
      @collaboration_stats = GamificationServiceResult.all.send("sort_by_#{@current_order}", "Collaboration::Agreement" )
      if @collaboration_stats != nil  && @collaboration_stats != []
        @service_stats.store("Collaboration::Agreement" , @agreements_stats)
      end
    end


  end

  def user 
    #@resources_map  = { "Debate" => "Discussioni","Proposal" => "Petizioni","Poll" => "Consultazioni certificate", "Crowdfunding" =>"Crowdfundings", "Event" =>"Eventi", "Legislation::Proposal" =>"Proposte ai progetti","Collaboration::Agreement" => "Patti di collaborazione"}
    #load_filtered_activity if valid_access?
  end
  
  

  private

  # def set_activity_counts
  #   @activity_counts = HashWithIndifferentAccess.new(
  #                         gamifications: (Setting['gamification_stats',User.pon_id] ? GamificationResult.sort_by_global_results.count : 0),
  #                         )
  #   end

    def gamification_params
      params.require(:gamification).permit()
    end
    
    # def load_filtered_activity
    #   set_activity_counts
    #   case params[:filter]
    #   when "gamification_stats" then load_gamification_stats
    #   else load_available_activity
    #   end
    # end

    # def load_gamification_stats
    #   @gamification_stats = GamificationResult.sort_by_global_results.page(params[:page])
    # end

    # def valid_access?
    #   #current_user.public_activity || authorized_current_user?
    # end

    # def authorized_current_user?
    #   @authorized_current_user ||= current_user && (current_user == @user || current_user.moderator? || current_user.administrator?)
    # end

    def load_data
      @resources_map  = {}

      @resources_map.store("Debate" , "Discussioni") #unless service?(:debates) == false
      @resources_map.store("Proposal" , "Petizioni") #unless service?(:proposals) == false
      @resources_map.store("Poll" , "Consultazioni certificate") #unless service?(:polls) == false
      @resources_map.store("Crowdfunding" , "Crowdfundings") #unless service?(:crowdfundings) == false
      @resources_map.store("Event" , "Eventi") #unless service?(:events) == false
      @resources_map.store("Legislation::Proposal" , "Proposte ai progetti") #unless service?(:processes) == false
      @resources_map.store("Collaboration::Agreement" , "Patti di collaborazione") #unless service?(:collaboration) == false

       #,"Proposal" => "Petizioni","Poll" => "Consultazioni certificate", "Crowdfunding" =>"Crowdfundings", "Event" =>"Eventi", "Legislation::Proposal" =>"Proposte ai progetti","Collaboration::Agreement" => "Patti di collaborazione"}
    end  



    
end
