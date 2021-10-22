class Admin::StatsController < Admin::BaseController

  def show
    @event_types = Ahoy::Event.group(:name).count

    @visits = Visit.count
    @debates = Debate.by_user_pon.with_hidden.count
    @proposals = Proposal.by_user_pon.with_hidden.count
    @crowdfundings = Crowdfunding.by_user_pon.with_hidden.count
    @comments = Comment.by_user_pon.not_valuations.with_hidden.count
    @debate_votes = Vote.by_user_pon.includes(:user).where(votable_type: 'Debate').where(users: { pon_id: User.pon_id }).count
    @proposal_votes = Vote.by_user_pon.includes(:user).where(votable_type: 'Proposal').where(users: { pon_id: User.pon_id }).count
    @crowdfunding_votes = Vote.by_user_pon.includes(:user).where(votable_type: 'Crowdfunding').where(users: { pon_id: User.pon_id }).count
    @comment_votes = Vote.by_user_pon.includes(:user).where(votable_type: 'Comment').where(users: { pon_id: User.pon_id }).count
    @votes = Vote.by_user_pon.includes(:user).where(users: { pon_id: User.pon_id }).count

    @user_level_two = User.by_user_pon.active.level_two_verified.count
    @user_level_three = User.by_user_pon.active.level_three_verified.count
    @verified_users = User.by_user_pon.active.level_two_or_three_verified.count
    @unverified_users = User.by_user_pon.active.unverified.count
    @users = User.by_user_pon.active.count
    @user_ids_who_voted_proposals = ActsAsVotable::Vote.by_user_pon.where(votable_type: 'Proposal').distinct.count(:voter_id)
    @user_ids_who_didnt_vote_proposals = @verified_users - @user_ids_who_voted_proposals
    @user_ids_who_voted_crowdfundings = ActsAsVotable::Vote.by_user_pon.where(votable_type: 'Crowdfunding').distinct.count(:voter_id)
    @user_ids_who_didnt_vote_crowdfundings = @verified_users - @user_ids_who_voted_crowdfundings
    @spending_proposals = SpendingProposal.by_user_pon.count
    budgets_ids = Budget.by_user_pon.where.not(phase: 'finished').pluck(:id)
    @budgets = budgets_ids.size
    @investments = Budget::Investment.by_user_pon.where(budget_id: budgets_ids).count
  end

  def proposal_notifications
    @proposal_notifications = ProposalNotification.all
    @proposals_with_notifications = @proposal_notifications.select(:proposal_id).distinct.count
  end

  def crowdfunding_notifications
    @crowdfunding_notifications = CrowdfundingNotification.all
    @crowdfundings_with_notifications = @crowdfunding_notifications.select(:crowdfunding_id).distinct.count
  end

  def direct_messages
    @direct_messages = DirectMessage.count
    @users_who_have_sent_message = DirectMessage.select(:sender_id).distinct.count
  end

  def polls
    @polls = ::Poll.current
    @participants = ::Poll::Voter.where(poll: @polls)
  end

end
