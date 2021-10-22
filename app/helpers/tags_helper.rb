module TagsHelper

  def taggables_path(taggable_type, tag_name)
    case taggable_type
    when 'event'
      events_path(search: tag_name)
    when 'asset'
      assets_path(search: tag_name)
    when 'debate'
      debates_path(search: tag_name)
    when 'proposal'
      proposals_path(search: tag_name)
    when 'crowdfunding'
      crowdfundings_path(search: tag_name)
    when 'reporting'
      reportings_path(search: tag_name)
    when 'budget/investment'
      budget_investments_path(@budget, search: tag_name)
    when 'legislation/proposal'
      legislation_process_proposals_path(@process, search: tag_name)
    when 'legislation/process'
      legislation_processes_path(@process, search: tag_name)  
    when 'collaboration/agreement'
      collaboration_agreements_path(@agreement, search: tag_name)
    when 'agreement'
      collaboration_agreements_path(@agreement, search: tag_name)   
    when 'chance'
      chances_path(@process, search: tag_name)  
    when 'work'
      works_path(@process, search: tag_name)
    when 'processes_proposals'  
      processes_proposals_path(@process, search: tag_name)  
    else
      '#'
    end
  end

  def taggable_path(taggable)
    taggable_type = taggable.class.name.underscore
    case taggable_type
    when 'event'
      event_path(taggable)
    when 'asset'
      asset_path(taggable)
    when 'debate'
      debate_path(taggable)
    when 'proposal'
      proposal_path(taggable)
    when 'crowdfunding'
      crowdfunding_path(taggable)
    when 'reporting'
      reporting_path(taggable)
    when 'budget/investment'
      budget_investment_path(taggable.budget_id, taggable)
    when 'legislation/proposal'
      legislation_process_proposal_path(@process, taggable)
    when 'legislation/process'
      legislation_processes_path(@process, taggable)  
    when 'collaboration/agreement'
      collaboration_agreements_path(@agreement, taggable)
    when 'agreement'
      collaboration_agreements_path(@agreement, taggable)  
    when 'chance'
      chances_path(@process, taggable)   
    when 'work'
      works_path(@process, taggable)
    when 'processes_proposals'  
      processes_proposals_path(@process, taggable)   
    else         
      '#'
    end
  end

end
