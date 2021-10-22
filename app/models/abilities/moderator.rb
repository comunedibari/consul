module Abilities
  class Moderator
    include CanCan::Ability

    def initialize(user,params,isBlockedPrivacy)
      merge Abilities::Moderation.new(user,params,isBlockedPrivacy)

      can :comment_as_moderator, [Debate, Comment, Proposal,Crowdfunding, Reporting, Budget::Investment, Poll::Question,
                                  Legislation::Question, Legislation::Annotation, Legislation::Proposal, Topic, Event,Poll, Collaboration::Agreement]

      #Permessi cf, cf notification e cf reward
      can :create, Crowdfunding do |crowdfunding|
          crowdfunding.creable_by?(user)
      end

      can [:update, :destroy, :edit], Crowdfunding do |item|
          item.editable_by?(user)
      end

      can [:toedit], Crowdfunding

      can [:retire_form, :retire], Crowdfunding, author_id: user.id

      can [:create, :show], CrowdfundingNotification, crowdfunding: {author_id: user.id}

      can [:delete_reward, :hide], CrowdfundingReward, author_id: user.id

      can [:update, :destroy, :edit], CrowdfundingReward do |item|
        item.editable_by?(user)
      end

      can :create, CrowdfundingReward do |item|
           item.creable_by?(user)
      end

      # Blocchiamo rotta creazione userinvestment
      cannot [:new, :create], UserInvestment

    end
  end
end
