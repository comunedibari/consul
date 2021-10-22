class Community < ActiveRecord::Base
  has_one :proposal
  has_one :crowdfunding

  
  has_one :reporting #mia

  has_one :investment, class_name: Budget::Investment
  has_many :topics

  def participants
    users_participants = users_who_commented +
                         users_who_topics_author +
                         author_from_community +
                         author_from_community_crowdfunding +  
                         author_from_community_reporting   
    users_participants.uniq
  end

  def from_resource
    if proposal.present?
      proposal 
    elsif crowdfunding.present?
      crowdfunding
    elsif reporting.present?
      reporting
    end

  end

  def from_proposal?
    proposal.present?
  end
  
  #mia
  def from_reporting?
    reporting.present?
  end

  def from_crowdfunding?
    crowdfunding.present?
  end

  private

  def users_who_commented
    topics_ids = topics.pluck(:id)
    query = "comments.commentable_id IN (?)and comments.commentable_type = 'Topic'"
    User.by_comments(query, topics_ids)
  end

  def users_who_topics_author
    author_ids = topics.pluck(:author_id)
    User.by_authors(author_ids)
  end

  def author_from_community
    from_proposal? ? User.where(id: proposal&.author_id) : User.where(id: investment&.author_id)
  end

  #miaaa
  def author_from_community_reporting
    from_reporting? ? User.where(id: reporting&.author_id) : User.where(id: investment&.author_id) #miaa
  end

  def author_from_community_crowdfunding
    from_crowdfunding? ? User.where(id: crowdfunding&.author_id) : User.where(id: investment&.author_id) #miaa
  end

end
