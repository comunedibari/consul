module GuidesHelper

  def new_proposal_guide
    if feature?('guides') && Budget.current&.accepting?
      new_guide_path
    else
      new_proposal_path
    end
  end

  def new_asset_guide
    if feature?('guides') && Budget.current&.accepting?
      new_guide_path
    else
      new_asset_path
    end
  end  


  def new_event_guide
    if feature?('guides') && Budget.current&.accepting?
      new_guide_path
    else
      new_event_path
    end
  end
  def new_crowdfunding_guide
    if feature?('guides') && Budget.current&.accepting?
      new_guide_path
    else
      new_crowdfunding_path
    end
  end

  #miaaaa
  def new_reporting_guide
    if feature?('guides') && Budget.current&.accepting?
      new_guide_path
    else
      new_reporting_path
    end
  end
  def new_budget_investment_guide
    if feature?('guides')
      new_guide_path
    else
      new_budget_investment_path(current_budget)
    end
  end

end
