class StatsController < ApplicationController
  include FeatureFlags

  feature_flag :public_stats

  skip_authorization_check

  def index
    @visits = daily_cache('visits') { Visit.count }
    @debates = daily_cache('debates') { Debate.with_hidden.count }
    @proposals = daily_cache('proposals') { Proposal.with_hidden.count }
    @crowdfundings = daily_cache('crowdfundings') { Crowdfunding.with_hidden.count }
    @comments = daily_cache('comments') { Comment.not_valuations.with_hidden.count }
    @reportings = daily_cache('reportings') { Reporting.with_hidden.count }


    @debate_votes = daily_cache('debate_votes') { Vote.where(votable_type: 'Debate').count }
    @proposal_votes = daily_cache('proposal_votes') { Vote.where(votable_type: 'Proposal').count }
    @crowdfunding_votes = daily_cache('crowdfunding_votes') { Vote.where(votable_type: 'Crowdfunding').count }
    #commento io
    #@reporting_votes = daily_cache('reporting_votes') { Vote.where(votable_type: 'Reporting').count }
    @comment_votes = daily_cache('comment_votes') { Vote.where(votable_type: 'Comment').count }
    @votes = daily_cache('votes') { Vote.count }

    @verified_users = daily_cache('verified_users') { User.with_hidden.level_two_or_three_verified.count }
    @unverified_users = daily_cache('unverified_users') { User.with_hidden.unverified.count }
  end

  private

    def daily_cache(key, &block)
      Rails.cache.fetch("public_stats/#{Time.current.strftime('%Y-%m-%d')}/#{key}", &block)
    end
end
