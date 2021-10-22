module Abilities
  class Administrator
    include CanCan::Ability

    def initialize(user, params, isBlockedPrivacy)
      merge Abilities::Moderation.new(user, params, isBlockedPrivacy)

      can :restore, Comment
      cannot :restore, Comment, hidden_at: nil

      can :restore, Debate
      cannot :restore, Debate, hidden_at: nil

      can :restore, Proposal
      cannot :restore, Proposal, hidden_at: nil

      #can [:investments,:rewards, :approve_investment,:delete_investment], Crowdfunding
      can :restore, Crowdfunding
      cannot :restore, Crowdfunding, hidden_at: nil

      can :restore, Reporting
      cannot :restore, Reporting, hidden_at: nil

      can :restore, Event
      cannot :restore, Event, hidden_at: nil

      #inserimento ricompensa
      #can [:delete_reward,:hide], CrowdfundingReward, author_id: user.id
      can :restore, CrowdfundingReward
      cannot :restore, CrowdfundingReward, hidden_at: nil

      can :approve, BookingManager::ModerableBooking
      can :disapprove, BookingManager::ModerableBooking
      can :manage, Availability
      #can :change_status, BookingManager::ModerableBooking
      can :update, BookingManager::ModerableBooking

      #inserimento investimento
      can :restore, UserInvestment
      cannot :restore, UserInvestment, hidden_at: nil
      cannot [:new, :create], UserInvestment

      can :restore, Legislation::Proposal
      cannot :restore, Legislation::Proposal, hidden_at: nil

      can :restore, User
      cannot :restore, User, hidden_at: nil

      can :restore, Legislation::Process
      cannot :restore, Legislation::Process, hidden_at: nil

      can :restore, Collaboration::Agreement
      cannot :restore, Collaboration::Agreement, hidden_at: nil

      can :confirm_hide, Comment
      cannot :confirm_hide, Comment, hidden_at: nil

      can :social_flag, Debate
      can :moderation_flag, Debate
      can :confirm_hide, Debate
      cannot :confirm_hide, Debate, hidden_at: nil

      can :social_flag, Proposal
      can :moderation_flag, Proposal
      can :confirm_hide, Proposal
      cannot :confirm_hide, Proposal, hidden_at: nil

      can :social_flag, Crowdfunding
      can :moderation_flag, Crowdfunding
      can :confirm_hide, Crowdfunding
      cannot :confirm_hide, Crowdfunding, hidden_at: nil

      can :manage, Asset

      if !params.nil? && params[:user_id] == user.id.to_s
        cannot :user, Gamification
      end

      can :social_flag, Event
      can :moderation_flag, Event
      can :confirm_hide, Event
      cannot :confirm_hide, Event, hidden_at: nil

      can :social_flag, Reporting
      can :moderation_flag, Reporting
      can :confirm_hide, Reporting
      cannot :confirm_hide, Reporting, hidden_at: nil

      can :moderation_flag, Poll
      can :confirm_hide, Poll
      cannot :confirm_hide, Poll, hidden_at: nil
      can :social_flag, Poll
      can :documents, Poll::Question::Answer


      can :social_flag, Legislation::Proposal
      can :moderation_flag, Legislation::Proposal
      can :confirm_hide, Legislation::Proposal
      cannot :confirm_hide, Legislation::Proposal, hidden_at: nil

      can :social_flag, BookingManager::ModerableBooking

      can :confirm_hide, User
      cannot :confirm_hide, User, hidden_at: nil

      can :mark_featured, Debate
      can :unmark_featured, Debate

      can :comment_as_administrator, [Debate, Comment, Proposal, Crowdfunding, Reporting, Poll, Budget::Investment,
                                      Legislation::Question, Legislation::Proposal, Legislation::Annotation, Topic, Event, Collaboration::Agreement]

      can [:search, :create, :index, :destroy], ::Administrator
      can [:search, :create, :index, :destroy], ::Moderator
      can [:search, :show, :edit, :update, :create, :index, :destroy, :summary], ::Valuator
      can [:search, :create, :index, :destroy], ::Manager
      can [:search, :index], ::User

      can :manage, Annotation

      can [:read, :update, :valuate, :destroy, :summary], SpendingProposal

      can [:index, :read, :new, :create, :update, :destroy, :calculate_winners, :read_results], Budget
      can [:read, :create, :update, :destroy], Budget::Group
      can [:read, :create, :update, :destroy], Budget::Heading
      can [:hide, :update, :toggle_selection], Budget::Investment
      can [:valuate, :comment_valuation], Budget::Investment
      can :create, Budget::ValuatorAssignment

      can [:search, :edit, :update, :create, :index, :destroy], Banner
      can [:search, :edit, :update, :create, :index, :destroy, :relation, :rem_relation, :downloadxlsx], Sector

      can [:index, :create, :edit, :update, :destroy], Geozone


      can :manage, SiteCustomization::Page
      can :manage, SiteCustomization::Image
      can :manage, SiteCustomization::ContentBlock

      can :social_flag, ::Legislation::Process
      can [:manage], ::Legislation::Process

      can [:create, :edit, :update], ::Collaboration::Agreement

      can [:update], ::Collaboration::Agreement do |item|
        item.editable_by?(user)
      end

      can [:destroy], ::Collaboration::Agreement do |item|
        item.editable_by?(user) && item.subscriptions.count == 0
      end


      can [:manage], ::Legislation::DraftVersion
      can [:manage], ::Legislation::Question
      can [:manage], ::Collaboration::AgreementRequirement

      can [:manage], ::Legislation::Proposal
      cannot :comment_as_moderator, [::Legislation::Question, Legislation::Annotation, ::Legislation::Proposal]

      can [:create], Document
      can [:create, :destroy], DirectUpload

      can [:deliver], Newsletter, hidden_at: nil

      #Permessi cf, cf notification e cf reward
      can :create, Crowdfunding do |crowdfunding|
        crowdfunding.creable_by?(user)
      end

      can [:toedit], Crowdfunding
      
      can [:update, :destroy, :edit], Crowdfunding do |crowdfunding|
        crowdfunding.editable_by?(user)
      end

      can [:retire_form, :retire], Crowdfunding, author_id: user.id

      can [:create, :show], CrowdfundingNotification, crowdfunding: {author_id: user.id}

      can [:delete_reward, :hide], CrowdfundingReward, author_id: user.id

      can :update, CrowdfundingReward do |crowdfunding_reward|
        crowdfunding_reward.editable_by?(user)
      end

      can :create, CrowdfundingReward do |item|
        item.creable_by?(user)
      end

      can [:update, :destroy, :edit], CrowdfundingReward do |item|
        item.editable_by?(user)
      end

    end
  end
end
