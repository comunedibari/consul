module Abilities
  class Moderation
    include CanCan::Ability

    def initialize(user,params,isBlockedPrivacy)
      merge Abilities::Common.new(user,params,isBlockedPrivacy)

      can :read, Organization
      can(:verify, Organization){ |o| !o.verified? }
      can(:reject, Organization){ |o| !o.rejected? }

      can :read, Comment

      can :hide, Comment, hidden_at: nil
      cannot :hide, Comment, user_id: user.id
      can :confirm_hide, Comment, moderation_entity: 2

      can :ignore_flag, Comment, ignored_flag_at: nil, hidden_at: nil
      cannot :ignore_flag, Comment, user_id: user.id

      can :ignore_flag_appr, Comment, moderation_entity: 2
      cannot :ignore_flag_appr, Comment, moderation_entity: 1

      can :moderate, Comment
      cannot :moderate, Comment, user_id: user.id



      #DEBATE
      can :moderation_flag, Debate
      can :hide, Debate, hidden_at: nil
      cannot :hide, Debate, author_id: user.id
      can :confirm_hide, Debate, moderation_entity: 2

      can :ignore_flag, Debate, ignored_flag_at: nil, hidden_at: nil
      cannot :ignore_flag, Debate, author_id: user.id

      can :moderate, Debate
      cannot :moderate, Debate, author_id: user.id

      can :ignore_flag_appr, Debate, moderation_entity: 2
      cannot :ignore_flag_appr, Debate, moderation_entity: 1


      #PROPOSAL

      can :moderation_flag, Proposal
      can :hide, Proposal, hidden_at: nil
      cannot :hide, Proposal, author_id: user.id
      can :confirm_hide, Proposal, moderation_entity: 2

      #can(:ignore_flag, Proposal){ |p| !p.ignored_flag_at && (!hiddent_at || flags_count == -2)}

      can :ignore_flag, Proposal, ignored_flag_at: nil, hidden_at: nil
      cannot :ignore_flag, Proposal, author_id: user.id

      can :ignore_flag_appr, Proposal, moderation_entity: 2
      cannot :ignore_flag_appr, Proposal, moderation_entity: 1

      can :moderate, Proposal
      cannot :moderate, Proposal, author_id: user.id

          #PROCESS
    #moderazione su process inizio
      can :read, Legislation::Process
      can :moderation_flag, Legislation::Process
      can :hide, Legislation::Process, hidden_at: nil
      cannot :hide, Legislation::Process, author_id: user.id
      can :confirm_hide, Legislation::Process, moderation_entity: 2

      can :ignore_flag, Legislation::Process, hidden_at: nil
      cannot :ignore_flag, Legislation::Process, author_id: user.id

      can :moderate, Legislation::Process
      cannot :moderate, Legislation::Process, author_id: user.id

      can :ignore_flag_appr, Legislation::Process, moderation_entity: 2
      cannot :ignore_flag_appr, Legislation::Process, moderation_entity: 1
    #moderazione su process fine


          #Agreement
    #moderazione su Agreement inizio
      can :read, Collaboration::Agreement
      can :moderation_flag, Collaboration::Agreement
      can :hide, Collaboration::Agreement, hidden_at: nil
      cannot :hide, Collaboration::Agreement, author_id: user.id
      can :confirm_hide, Collaboration::Agreement, moderation_entity: 2

      can :ignore_flag, Collaboration::Agreement, hidden_at: nil
      cannot :ignore_flag, Collaboration::Agreement, author_id: user.id

      can :moderate, Collaboration::Agreement
      cannot :moderate, Collaboration::Agreement, author_id: user.id

      can :ignore_flag_appr, Collaboration::Agreement, moderation_entity: 2
      cannot :ignore_flag_appr, Collaboration::Agreement, moderation_entity: 1
    #moderazione su Agreement fine


      #Crowdfunding

      can :moderation_flag, Crowdfunding
      can :hide, Crowdfunding, hidden_at: nil
      cannot :hide, Crowdfunding, author_id: user.id
      can :confirm_hide, Crowdfunding, moderation_entity: 2

      can :ignore_flag, Crowdfunding, ignored_flag_at: nil, hidden_at: nil
      cannot :ignore_flag, Crowdfunding, author_id: user.id

      can :moderate, Crowdfunding
      cannot :moderate, Crowdfunding, author_id: user.id

      can :ignore_flag_appr, Crowdfunding, moderation_entity: 2
      cannot :ignore_flag_appr, Crowdfunding, moderation_entity: 1

          #REPORTING
      #moderazione su reporting inizio
      can :moderation_flag, Reporting
      can :hide, Reporting, hidden_at: nil
      cannot :hide, Reporting, author_id: user.id
      can :confirm_hide, Reporting, moderation_entity: 2

      can :ignore_flag, Reporting, ignored_flag_at: nil, hidden_at: nil
      cannot :ignore_flag, Reporting, author_id: user.id

      can :moderate, Reporting
      cannot :moderate, Reporting, author_id: user.id

      can :ignore_flag_appr, Reporting, moderation_entity: 2
      cannot :ignore_flag_appr, Reporting, moderation_entity: 1
    #moderazione su reporting fine

              #REPORTING
      #moderazione su event inizio
      can :moderation_flag, Event
      can :hide, Event, hidden_at: nil
      cannot :hide, Event, author_id: user.id
      can :confirm_hide, Event, moderation_entity: 2

      can :ignore_flag, Event, ignored_flag_at: nil, hidden_at: nil
      cannot :ignore_flag, Event, author_id: user.id

      can :moderate, Event
      cannot :moderate, Event, author_id: user.id

      can :ignore_flag_appr, Event, moderation_entity: 2
      cannot :ignore_flag_appr, Event, moderation_entity: 1
    #moderazione su reporting fine

      can :moderation_flag, Legislation::Question
      can :moderate, Legislation::Question

      can :moderation_flag, Legislation::Proposal
      can :hide, Legislation::Proposal, hidden_at: nil
      cannot :hide, Legislation::Proposal, author_id: user.id

      can :ignore_flag, Legislation::Proposal, ignored_flag_at: nil, hidden_at: nil
      cannot :ignore_flag, Legislation::Proposal, author_id: user.id

      can :moderate, Legislation::Proposal
      cannot :moderate, Legislation::Proposal, author_id: user.id

      can :hide, User
      cannot :hide, User, id: user.id

      can :block, User
      cannot :block, User, id: user.id


      #POLL
      can [:download_result,:read, :create, :update, :destroy, :add_question, :search_booths, :search_officers, :booth_assignments, :results, :stats], Poll, pon_id: user.pon_id
      can [:create], ::Poll::Question
      can [:read, :update], ::Poll::Question, pon_id: user.pon_id
      can [:destroy,:update], Poll::Question, pon_id: user.pon_id  , comments_count: 0, answers_count_from_users:0 #,votes_up: 0
      can [:create,:delete,:update], ::Poll::Question::Answer
      can [:read, :update, :destroy, :order_answers,:delete], ::Poll::Question::Answer, pon_id: user.pon_id


      can [:read, :create, :update, :destroy, :available], Poll::Booth
      can [:search, :create, :index, :destroy], ::Poll::Officer
      can [:create, :destroy, :manage], ::Poll::BoothAssignment
      can [:create, :destroy], ::Poll::OfficerAssignment

      can [:outcome, :actions, :read], Sector

    end
  end
end
