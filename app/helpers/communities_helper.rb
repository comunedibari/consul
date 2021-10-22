module CommunitiesHelper

  def community_title(community)
    community.from_resource.title
  end

  def community_text(community)
   if community.from_proposal? 
     t("community.show.title.proposal") 
   elsif community.from_crowdfunding?
      t("community.show.title.crowdfunding") 
   elsif community.from_reporting?
    t("community.show.title.reporting") 
   else
     t("community.show.title.investment")
   end
  end

  def community_description(community)
    if community.from_proposal? 
      t("community.show.description.proposal")
    elsif community.from_crowdfunding? 
      t("community.show.description.crowdfunding")
    elsif community.from_reporting?
      t("community.show.description.reporting") 
    else
      t("community.show.description.investment")
    end
  end

  def author?(community, participant)
    community.from_resource.author_id == participant.id
  end

  def community_back_link_path(community)
    if community.from_proposal?
      proposal_path(community.proposal)
    elsif community.from_crowdfunding? #miaaa
      crowdfunding_path(community.crowdfunding)
    elsif community.from_reporting? #miaaa
      reporting_path(community.reporting)
    else
      budget_investment_path(community.investment.budget_id, community.investment)
    end
  end

  def community_access_text(community)
    if community.from_proposal? 
      t("community.sidebar.description.proposal")
    elsif community.from_crowdfunding?
      t("community.sidebar.description.crowdfunding")
    elsif community.from_reporting?
      t("community.sidebar.description.reporting") 
    else
      t("community.sidebar.description.investment")
    end
  
  end

  def create_topic_link(community)
    current_user.present? ? new_community_topic_path(community.id) : go_to_login
  end
end
