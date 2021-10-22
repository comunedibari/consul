ActsAsVotable::Vote.class_eval do
  include Graphqlable

  belongs_to :signature
  belongs_to :votable, polymorphic: true
  belongs_to :voter, polymorphic: true
  scope :by_user_pon,    -> { all  }
  scope :public_for_api, -> do
    where(%{(votes.votable_type = 'Debate' and votes.votable_id in (?)) or
            (votes.votable_type = 'Proposal' and votes.votable_id in (?)) or
            (votes.votable_type = 'Crowdfundings' and votes.votable_id in (?)) or
            (votes.votable_type = 'Reporting' and votes.votable_id in (?)) or    #mia
            (votes.votable_type = 'Comment' and votes.votable_id in (?)) or 
            (votes.votable_type = 'Event' and votes.votable_id in (?))},
          Debate.public_for_api.pluck(:id),
          Proposal.public_for_api.pluck(:id),
          Crowdfunding.public_for_api.pluck(:id),
          Reporting.public_for_api.pluck(:id),     #mia
          Comment.public_for_api.pluck(:id),
          Event.public_for_api.pluck(:id))
  end

  def self.for_debates(debates)
    where(votable_type: 'Debate', votable_id: debates)
  end

  def self.for_events(events)
    where(votable_type: 'Event', votable_id: events)
  end

  def self.for_proposals(proposals)
    where(votable_type: 'Proposal', votable_id: proposals)
  end
  
  #miaaaaaa
  def self.for_reportings(reportings)
    where(votable_type: 'Reporting', votable_id: reportings)
  end

  def self.for_crowdfundings(crowdfundings)
    where(votable_type: 'Crowdfunding', votable_id: crowdfundings)
  end

  def self.for_legislation_proposals(proposals)
    where(votable_type: 'Legislation::Proposal', votable_id: proposals)
  end

  def self.for_spending_proposals(spending_proposals)
    where(votable_type: 'SpendingProposal', votable_id: spending_proposals)
  end

  def self.for_budget_investments(budget_investments)
    where(votable_type: 'Budget::Investment', votable_id: budget_investments)
  end

  def value
    vote_flag
  end

end
