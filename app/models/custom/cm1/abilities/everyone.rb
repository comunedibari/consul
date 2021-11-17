module Abilities
  class Everyone
    include CanCan::Ability

    def is_invite_token_valid?(poll_id, invitation_token)
      poll_voter = Poll::Voter.find_by(poll_id: poll_id, token: invitation_token)

      # Perchè il token di invito sia valido, deve sia esistere il record associato
      # che essere stato inviato.
      if !poll_voter.nil? and poll_voter.invitation_sent
        true
      else
        false
      end

    end

    def initialize(user, params, isBlockedPrivacy)
      can [:read, :map, :json_data, :share, :large_map], Debate
      can [:read, :map, :json_data, :share, :large_map], Asset
      can [:read, :map, :summary, :share, :json_data, :large_map], Proposal
      can [:read, :map, :summary, :share, :json_data, :large_map], Crowdfunding
      can [:read, :map, :summary, :share, :json_data, :large_map], Reporting
      can [:map, :summary, :share, :json_data, :large_map, :relation], Sector #mia
      can [:read, :map, :summary, :share, :json_data, :large_map], SectorType #mia
      can [:read, :map, :summary, :share, :json_data, :large_map], Event
      can [:read, :map, :summary, :share, :json_data, :large_map], Legislation::Process

      can [:read], Sector do |sector|
        sector.visible
      end

      can [:read], UserInvestment #inserimento investimento
      can [:read], CrowdfundingReward #inserimento ricompensa

      #creare investimento anche come utente guest
      can [:new, :create], UserInvestment if user == nil
      can :share, UserInvestment
      # accedere alla rotta di controllo esito pagamento investimento
      can [:payment_outcome], Crowdfunding

      # user_guest = User.where(email: "guest@baripartecipa.dev").first
      # cannot [:new, :create], UserInvestment, crowdfunding: {author_id: user_guest.id}
      # cannot [:new, :create], UserInvestment, crowdfunding: {author_id: user.id} if user != nil

      can :read, Comment
      can :read, Poll

      can :answer, Poll do |poll|
        if poll.sondaggio_esterno
          user.nil? and is_invite_token_valid?(params[:id], params[:i_t])
        else
          poll.access_type == 3 and user.nil? and !poll.expired? and !poll.incoming?
        end
      end

      can :answer, Poll::Question do |question|
        # Consentiamo di rispondere alle domande agli utenti anonimi su Poll esterno
        # Il controllo di validità del token di voto avverrà nel controller
        if question.poll.sondaggio_esterno
          user.nil?
        else
          question.poll.access_type == 3 and user.nil? and !question.poll.expired? and !question.poll.incoming?
        end
      end

      can :confirm, Poll do |poll|
        poll.access_type == 3 and user.nil?
      end

      can :results, Poll do |poll|
        poll.expired? && poll.results_enabled?
      end
      can :stats, Poll do |poll|
        poll.expired? && poll.stats_enabled?
      end
      can :read, Poll::Question
      can [:read, :welcome], Budget
      can :read, SpendingProposal
      can :read, LegacyLegislation
      can [:read, :relation], User
      can [:search, :read], Annotation
      can [:read], Budget
      can [:read], Budget::Group
      can [:read, :print, :json_data], Budget::Investment
      can :read_results, Budget, phase: "finished"
      can :new, DirectMessage
      can [:read, :debate, :draft_publication, :sgap, :allegations, :details, :result_publication, :json_data, :proposals, :large_map], Legislation::Process, published: true
      can [:read, :debate, :draft_publication, :sgap, :allegations, :details, :result_publication, :json_data, :proposals, :large_map], Collaboration::Agreement, published: true
      can [:read, :changes, :go_to_version], Legislation::DraftVersion
      can [:read], Legislation::Question
      can [:read, :map, :share], Legislation::Proposal
      can [:search, :comments, :read, :create, :new_comment], Legislation::Annotation

    end
  end
end
