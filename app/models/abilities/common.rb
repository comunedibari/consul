module Abilities
  class Common
    include CanCan::Ability

    def initialize(user, params, isBlockedPrivacy)
      merge Abilities::Everyone.new(user, params, isBlockedPrivacy)

      can [:investments], Crowdfunding
      cannot [:investments], Crowdfunding, author_id: user.id

      #can [:share,:delete_investment, :hide], UserInvestment, user_id: user.id  --> actions disabilitate

      # manage dei cf sono demandati solo ad admin e mod
      #can [:delete_reward, :hide], CrowdfundingReward, author_id: user.id

      # if !isBlockedPrivacy
      #   can [:investments, :rewards, :approve_investment, :delete_investment], Crowdfunding
      # end

      #eliminate le azioni di approva e conferma investimento
      if !isBlockedPrivacy
        can [:investments, :rewards], Crowdfunding
      end

      # administraor or moderator
      if user.can_moderate?
        can :manage_hidden, [Debate, Proposal, Reporting, ::Legislation::Process, ::Collaboration::Agreement] do |element|
          false
        end
      end

      # administraor or moderator
      if user.can_sector_content?
        can :add_sector_content, [Debate, Proposal, Comment, Crowdfunding, Legislation::Proposal, Collaboration::Agreement] do |element|
          true
        end
      end

      can [:read, :update], User, id: user.id
      can [:create], UserTag
      can [:update, :destroy], UserTag, user_id: user.id

      can :read, Debate
      can :update, Debate do |debate|
        if !isBlockedPrivacy
          debate.editable_by?(user)
        end
      end

      can :read, Crowdfunding

      can :read, Proposal
      can :update, Proposal do |proposal|
        if !isBlockedPrivacy
          proposal.editable_by?(user)
        end
      end

      #can :read, StSector
      can [:edit, :delete], StSector do |st_sector|
        st_sector.editable_by?(user, st_sector.sector_id)
      end

      #can :read, Sector
      can [:edit, :delete], Sector do |sector|
        sector.editable_by?(user, sector.id)
      end

      can [:update, :clean_st], StSector do |st_sector|
        st_sector.cleanable_by?(user, st_sector.sector_id)
      end

      can [:update, :clean_st], Sector do |sector|
        sector.cleanable_by?(user, sector.id)
      end

      can :read, Event
      can :update, Event do |event|
        if !isBlockedPrivacy
          event.editable_by?(user)
        end
      end

      can :read, UserInvestment
      can :update, UserInvestment do |user_investment|
        #probabilmente non viene usata
        if !isBlockedPrivacy
          user_investment.editable_by?(user)
        end
      end

      can :read, CrowdfundingReward

      # manage dei cf sono demandati solo ad admin e mod
      # can :update, CrowdfundingReward do |crowdfunding_reward| #probabilmente non viene usata
      #   if !isBlockedPrivacy
      #     crowdfunding_reward.editable_by?(user)
      #   end
      # end

      can :read, Reporting
      # can :update, Reporting do |reporting|
      #   if !isBlockedPrivacy
      #     reporting.editable_by?(user)
      #   end
      # end

      can :read, ::Collaboration::Subscription do |item|
        item.readable_by?(user)
      end

      can :read, BookingManager::ModerableBooking

      can :read, ::Collaboration::Agreement

      can :read, ::Collaboration::AgreementRequirement

      can [:edit, :update, :destroy], ::Legislation::Proposal do |item|
        #commentata
        item.editable_by?(user)
      end

      can :read, ::Legislation::Process
      can :read, ::Legislation::DraftVersion
      can :read, ::Legislation::Question
      can :read, ::Legislation::Proposal
      can :read, ::Legislation::Answer

      can :read, Gamification
      can [:update, :destroy], Gamification, user_id: user.id
      can :user, Gamification

      #CREAZIONE SOCIAL/SPID
      can :create, Debate do |debate|
        if !isBlockedPrivacy
          debate.creable_by?(user)
        end
      end
      can :create, Proposal do |proposal|
        if !isBlockedPrivacy
          proposal.creable_by?(user)
        end
      end
      can :create, Reporting do |reporting|
        if !isBlockedPrivacy
          reporting.creable_by?(user)
        end
      end
      can :create, ::Legislation::Proposal do |legislation_proposal|
        if !isBlockedPrivacy
          legislation_proposal.creable_by?(user)
        end
      end
      can :create, Event do |event|
        if !isBlockedPrivacy
          event.creable_by?(user)
        end
      end

      can [:new, :create], UserInvestment do |item|
        if !isBlockedPrivacy
          item.creable_by?(user)
        end
      end

      cannot [:new, :create], UserInvestment if (user&.is_social? and !UserInvestment.creable_by_social?(params[:crowdfunding_id]))

      cannot [:new, :create], UserInvestment, crowdfunding: { author_id: user.id }

      # manage dei cf sono demandati solo ad admin e mod
      # can :create, CrowdfundingReward do |item|
      #   if !isBlockedPrivacy
      #     item.creable_by?(user)
      #   end
      # end

      can [:new, :create], Collaboration::Subscription do |item|
        if !isBlockedPrivacy
          item.creable_by?(user)
        end
      end
      can [:new, :create], BookingManager::ModerableBooking do |item|
        if !isBlockedPrivacy
          item.creable_by?(user)
        end
      end

      can [:new, :create], Legislation::Process do |process_processes_proposal|
        if !isBlockedPrivacy
          process_processes_proposal.processes_proposal_creable_by?(user)
        end
      end

      can [:new, :create], Legislation::Question do |process_processes_proposal|
        if !isBlockedPrivacy
          process_processes_proposal.processes_proposal_creable_by?(user)
        end
      end

      can [:new, :create, :share], StSector do |st_sector|
        st_sector.creable_by?(user)
      end

      can [:show], StSector do |st_sector|
        st_sector.visible_by?(user, st_sector)
      end

      can [:new, :create, :share], Sector do |sector|
        sector.creable_by?(user)
      end

      can [:show], Sector do |sector|
        sector.visible_by?(user)
      end

      if user.can_create?
        #can :create, Crowdfunding
        can :create, Reporting
        #can :create, Debate
        #can :create, Proposal
        #can :create, Event
        #can :create, ::Legislation::Process                      #commentata
        #can :create, ::Legislation::DraftVersion                 #commentata
        #can :create, ::Legislation::Question                     #commentata
        #can :create, ::Legislation::Proposal
        can :create, ::Legislation::Answer #commentata
        #can :create, ::Collaboration::AgreementRequirement       #commentata
      end

      #can [:new, :create], BookingManager::ModerableBooking
      can :create, Comment
      can :create, UserTag

      #can [:edit, :update, :destroy], ::Legislation::Process do |item|                      #commentata
      #item.editable_by?(user)
      #end
      #can [:edit, :update, :destroy], ::Legislation::DraftVersion do |item|                 #commentata
      #item.editable_by?(user)
      # end
      #can [:edit, :update, :destroy], ::Legislation::Question do |item|                     #commentata
      #item.editable_by?(user)
      #end
      #can [:edit, :update, :destroy], ::Collaboration::AgreementRequirement do |item|          #commentata
      #item.editable_by?(user)
      #end

      can [:retire_form, :retire], Reporting, author_id: user.id
      can [:retire_form, :retire], ::Legislation::Process, author_id: user.id
      can [:retire_form, :retire], ::Collaboration::Agreement, author_id: user.id
      can [:retire_form, :retire], Proposal, author_id: user.id
      can [:retire_form, :retire], Legislation::Proposal, author_id: user.id
      can [:retire_form, :retire], BookingManager::ModerableBooking, booker_id: user.id

      can :suggest, Debate
      can :suggest, Proposal
      can :suggest, Crowdfunding
      can :suggest, Legislation::Proposal
      can :suggest, ActsAsTaggableOn::Tag
      can :suggest, Reporting

      if !isBlockedPrivacy
        can [:flag, :unflag], Comment
        cannot [:flag, :unflag], Comment, user_id: user.id

        can [:flag, :unflag], Debate
        cannot [:flag, :unflag], Debate, author_id: user.id

        can [:flag, :unflag], Proposal
        cannot [:flag, :unflag], Proposal, author_id: user.id

        can [:flag, :unflag], Crowdfunding
        cannot [:flag, :unflag], Crowdfunding, author_id: user.id

        can [:flag, :unflag], Reporting
        cannot [:flag, :unflag], Reporting, author_id: user.id

        can [:flag, :unflag], Event
        cannot [:flag, :unflag], Event, author_id: user.id

        can [:flag, :unflag], Legislation::Proposal
        cannot [:flag, :unflag], Legislation::Proposal, author_id: user.id

        can [:flag, :unflag], Legislation::Process
        cannot [:flag, :unflag], Legislation::Process, author_id: user.id

        can [:flag, :unflag], Collaboration::Agreement
        cannot [:flag, :unflag], Collaboration::Agreement, author_id: user.id

        can [:create, :destroy], Follow

        can [:destroy], Document, documentable: { author_id: user.id }

        can [:destroy], Image, imageable: { author_id: user.id }

        can [:create, :destroy], DirectUpload
      end

      unless user.organization?
        can :vote, Debate
        can :vote, Event
        can :vote, Comment
      end

      if user.level_two_or_three_verified?
        can :vote, Proposal
        can :vote_featured, Proposal
        can :vote, Event
        can :vote_featured, Event
        can :vote, Crowdfunding
        can :vote_featured, Crowdfunding
        can :vote, Reporting
        can :vote_featured, Reporting
        can :vote, SpendingProposal
        can :create, SpendingProposal

        can :vote, Legislation::Proposal
        can :vote_featured, Legislation::Proposal

        can :create, Budget::Investment, budget: { phase: "accepting" }
        can :suggest, Budget::Investment, budget: { phase: "accepting" }
        can :destroy, Budget::Investment, budget: { phase: ["accepting", "reviewing"] }, author_id: user.id
        can :vote, Budget::Investment, budget: { phase: "selecting" }

        can [:show, :create], Budget::Ballot, budget: { phase: "balloting" }
        can [:create, :destroy], Budget::Ballot::Line, budget: { phase: "balloting" }

        can :create, DirectMessage
        can :show, DirectMessage, sender_id: user.id

        can :confirm, Poll do |poll|
          if !isBlockedPrivacy
            !poll.vote_has_been_confirmed?(user) && poll.confirmable_by?(user)
          end
        end
        can :answer, Poll do |poll|
          if !isBlockedPrivacy
            poll.answerable_by?(user) && !poll.vote_has_been_confirmed?(user)
          end
        end
        can :answer, Poll::Question do |question|
          if !isBlockedPrivacy
            question.answerable_by?(user)
          end
        end

      end

      can [:results, :stats], Poll, pon_id: user.pon_id

      can [:create, :show], Collaboration::AgreementNotification, collaboration_agreement: { author_id: user.id }
      can [:create, :show], ProposalNotification, proposal: { author_id: user.id }

      can [:create, :show], ReportingNotification, reporting: { author_id: user.id }

      can :create, Annotation
      can [:update, :destroy], Annotation, user_id: user.id

      can [:create], Topic
      can [:update, :destroy], Topic, author_id: user.id

      can :preferences, User

      # Always performed
      can :access, :ckeditor # needed to access Ckeditor filebrowser

      # Performed checks for actions:
      can [:read, :create, :destroy], Ckeditor::Picture
      can [:read, :create, :destroy], Ckeditor::AttachmentFile

    end
  end
end
