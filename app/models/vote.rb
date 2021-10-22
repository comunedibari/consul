class Vote < ActsAsVotable::Vote
    

    belongs_to :debate, -> { where(votes: {votable_type: 'Debate'}) }, foreign_key: 'votable_id'
    belongs_to :event, -> { where(votes: {votable_type: 'Event'}) }, foreign_key: 'votable_id'
    belongs_to :proposal, -> { where(votes: {votable_type: 'Proposal'}) }, foreign_key: 'votable_id'
    belongs_to :crowdfunding, -> { where(votes: {votable_type: 'Crowdfunding'}) }, foreign_key: 'votable_id'
    belongs_to :reporting, -> { where(votes: {votable_type: 'Reporting'}) }, foreign_key: 'votable_id'
    belongs_to :comment, -> { where(votes: {votable_type: 'Comment'}) }, foreign_key: 'votable_id'
    belongs_to :user, -> { where(votes: {voter_type: 'User'}) }, foreign_key: 'voter_id'

end
