class UsersController < ApplicationController
  has_filters %w{proposals processes crowdfundings processes_proposals reportings debates budget_investments collaboration_agreements comments follows events moderable_bookings}, only: :show

  load_and_authorize_resource
  helper_method :author?
  helper_method :valid_interests_access?

  def show
    load_filtered_activity if valid_access?
    #add user breadcrumb
    add_breadcrumb @user.username
  end

  private

    def set_activity_counts
      @activity_counts = HashWithIndifferentAccess.new(
                          #proposals: (Setting['service.proposals',User.pon_id] ? Proposal.where(author_id: @user.id).count: 0),
                          #crowdfundings: (Setting['service.crowdfundings',User.pon_id] ? Crowdfunding.where(author_id: @user.id).count: 0),
                          #events: (Setting['service.events',User.pon_id] ? Event.where(author_id: @user.id).count: 0),
                          #reportings: (Setting['service.reportings',User.pon_id] ? Reporting.where(author_id: @user.id).count: 0),
                          #processes: (Setting['service.processes',User.pon_id] ? ::Legislation::Process.process_standard.where(author_id: @user.id).count: 0),
                          #agreements: (Setting['service.collaboration',User.pon_id] ? ::Collaboration::Agreement.where(author_id: @user.id).count: 0),
                          #processes_proposals: (Setting['service.proposals',User.pon_id] ? ::Legislation::Proposal.where(author_id: @user.id).count: 0),
                          #collaboration_agreements: (Setting['service.collaboration',User.pon_id] ? ::Collaboration::Agreement.where(author_id: @user.id).count: 0),
                          #debates: (Setting['service.debates',User.pon_id] ? Debate.where(author_id: @user.id).count: 0),
                          #moderable_bookings: (Setting['service.assets',User.pon_id] ? ::BookingManager::ModerableBooking.where(booker_id: @user.id).count: 0),
                          #budget_investments: (Setting['service.budgets',User.pon_id] ? Budget::Investment.where(author_id: @user.id).count : 0),
                          
                          proposals: (Proposal.where(author_id: @user.id).count),
                          crowdfundings: (Crowdfunding.where(author_id: @user.id).count),
                          events: (Event.where(author_id: @user.id).count),
                          reportings: (Reporting.where(author_id: @user.id).count),
                          processes: (::Legislation::Process.process_standard.where(author_id: @user.id).count),
                          #processes_proposals: (::Legislation::Proposal.where(author_id: @user.id).count),
                          processes_proposals: count_proposal,
                          collaboration_agreements: (::Collaboration::Agreement.where(author_id: @user.id).count),
                          debates: (Debate.where(author_id: @user.id).count),
                          moderable_bookings: (::BookingManager::ModerableBooking.where(booker_id: @user.id).count),
                          budget_investments: (Budget::Investment.where(author_id: @user.id).count),
                          
                          comments: only_active_commentables.count,
                          follows: @user.follows.count)
    end

    def load_filtered_activity
      set_activity_counts
      case params[:filter]
      when "proposals" then load_proposals
      when "crowdfundings" then load_crowdfundings
      when "events" then load_events
      when "reportings" then load_reportings
      when "processes"   then load_processes
      #when "agreements"   then load_agreements
      when "processes_proposals"   then load_processes_proposals
      when "collaboration_agreements"   then load_collaboration_agreements  
      when "debates"   then load_debates
      when "budget_investments" then load_budget_investments
      when "comments" then load_comments
      when "follows" then load_follows
      when "moderable_bookings" then load_moderable_bookings
      else load_available_activity
      end
    end

    def load_available_activity
      ctrl_service? "crowdfundings"
      if @activity_counts[:proposals] > 0 and ctrl_service? "proposals"
        load_proposals
        @current_filter = "proposals"
      elsif @activity_counts[:crowdfundings] > 0 and ctrl_service? "crowdfundings"
        load_crowdfundings
        @current_filter = "crowdfundings"
      elsif @activity_counts[:events] > 0 and ctrl_service? "events"
        load_events
        @current_filter = "events"        
      elsif @activity_counts[:reportings] > 0 and ctrl_service? "reportings"
        load_reportings
        @current_filter = "reportings"
      elsif @activity_counts[:processes] > 0 and ctrl_service? "processes"
        load_processes
        @current_filter = "processes"
      # elsif @activity_counts[:agreements] > 0
      #   load_agreements
      #   @current_filter = "agreements"
      elsif @activity_counts[:collaboration_agreements] > 0 and ctrl_service? "collaboration_agreements"
        load_collaboration_agreements
        @current_filter = "collaboration_agreements"        
      elsif @activity_counts[:processes_proposals] > 0 and (ctrl_service? "chances" or ctrl_service? "works")
        load_processes_proposals
        @current_filter = "processes_proposals" 
      elsif @activity_counts[:debates] > 0 and ctrl_service? "debates"
        load_debates
        @current_filter = "debates"
      #elsif  @activity_counts[:budget_investments] > 0 and ctrl_service? "budget_investments"
      #  load_budget_investments
      #  @current_filter = "budget_investments"
      elsif  @activity_counts[:comments] > 0 and ctrl_service? "comments"
        load_comments
        @current_filter = "comments"
      elsif  @activity_counts[:follows] > 0 and ctrl_service? "follows"
        load_follows
        @current_filter = "follows"
      elsif  @activity_counts[:moderable_bookings] > 0 and ctrl_service? "moderable_bookings"
        load_moderable_bookings
        @current_filter = "moderable_bookings"
      end
    end

    def ctrl_service? filter      
      has_service = {
        "proposals" => 'proposals',
        "processes" => 'processes',
        "crowdfundings" => 'crowdfundings',
        "works" => 'works',
        "chances" => 'chances',
        "reportings" => 'reportings',
        "debates" => 'debates',
        #"budget_investments" => 'budgets',
        "collaboration_agreements" => 'collaboration',
        #"comments" => 'comments',
        #"follows" => 'follows', #no
        "events" => 'events',
        "moderable_bookings" => 'assets'
      }

      if has_service[filter].nil? or Setting.where(pon_id: current_user.pon_id).where(key: "service."+has_service[filter]).nil? or
        Setting.where(pon_id: current_user.pon_id).where(key: "service."+has_service[filter]).count == 0 or
        Setting.where(pon_id: current_user.pon_id).where(key: "service."+has_service[filter]).first.value == "true"
        true
      else
        false
      end
    end

    def load_moderable_bookings
      @moderable_bookings = BookingManager::ModerableBooking.where(booker_id: @user.id).order(created_at: :desc).page(params[:page])
    end

    def load_proposals
      @proposals = Proposal.where(author_id: @user.id).order(created_at: :desc).page(params[:page])
    end

    def load_crowdfundings
      @crowdfundings = Crowdfunding.where(author_id: @user.id).order(created_at: :desc).page(params[:page])
    end

    def load_events
      @events = Event.where(author_id: @user.id).order(created_at: :desc).page(params[:page])
    end

    def load_reportings
      @reportings = Reporting.where(author_id: @user.id).order(created_at: :desc).page(params[:page])
    end

    def load_processes
      @processes = ::Legislation::Process.process_standard.where(author_id: @user.id).order(created_at: :desc).page(params[:page]) 
    end

    # def load_agreements
    #   @agreements = ::Collaboration::Agreement.where(author_id: @user.id).order(created_at: :desc).page(params[:page]) 
    # end 
    
    def load_collaboration_agreements
      @collaboration_agreements = ::Collaboration::Agreement.where(author_id: @user.id).order(created_at: :desc).page(params[:page]) 
    end 

    def load_processes_proposals

      if ctrl_service? "chances" and ctrl_service? "works"
        @processes_proposals = ::Legislation::Proposal.where(author_id: @user.id).order(created_at: :desc).page(params[:page]) 
      elsif ctrl_service? "chances" 
        @processes_proposals = ::Legislation::Proposal.joins(:process).where("process_type in (3,5) ").where(author_id: @user.id).order(created_at: :desc).page(params[:page]) 
      elsif ctrl_service? "works" 
        @processes_proposals = ::Legislation::Proposal.joins(:process).where("process_type in (2,4) ").where(author_id: @user.id).order(created_at: :desc).page(params[:page])  
      end
    end

    def count_proposal
      if ctrl_service? "chances" and ctrl_service? "works"
        return ::Legislation::Proposal.where(author_id: @user.id).order(created_at: :desc).page(params[:page]).count
      elsif ctrl_service? "chances" 
        return ::Legislation::Proposal.joins(:process).where("process_type in (3,5) ").where(author_id: @user.id).order(created_at: :desc).page(params[:page]).count
      elsif ctrl_service? "works" 
        return ::Legislation::Proposal.joins(:process).where("process_type in (2,4) ").where(author_id: @user.id).order(created_at: :desc).page(params[:page]).count  
      end

    end

    def load_debates
      @debates = Debate.where(author_id: @user.id).order(created_at: :desc).page(params[:page])
    end

    def load_comments
      @comments = only_active_commentables.includes(:commentable).order(created_at: :desc).page(params[:page])
    end

    def load_budget_investments
      @budget_investments = Budget::Investment.where(author_id: @user.id).order(created_at: :desc).page(params[:page])
    end

    def load_follows
      @follows = @user.follows.group_by(&:followable_type)
    end

    def valid_access?
      @user.public_activity || authorized_current_user?
    end

    def valid_interests_access?
      @user.public_interests || authorized_current_user?
    end

    def author?(proposal)
      proposal.author_id == current_user.id if current_user
    end

    def authorized_current_user?
      @authorized_current_user ||= current_user && (current_user == @user || current_user.moderator? || current_user.administrator?)
    end

    def all_user_comments
      Comment.not_valuations.not_as_admin_or_moderator.where(user_id: @user.id)
    end

    def only_active_commentables
      disabled_commentables = []
      disabled_commentables << "Debate" unless Setting['service.debates',User.pon_id]
      disabled_commentables << "Budget::Investment" unless Setting['feature.budgets',User.pon_id]

      if disabled_commentables.present?
        all_user_comments.where("commentable_type NOT IN (?)", disabled_commentables)
      else
        all_user_comments
      end
    end


end
