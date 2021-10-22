module AgreementHelper

  def collaboration_agreement_back_link(agreement)
    ret = collaboration_agreements_path
    if agreement.agreement_type == 2
      ret = subscriptions_path
    elsif agreement.agreement_type == 1
      ret = agreement   
    end
    ret
  end

  def namespaced_agreement_path(agreement, options = {})
    @namespace_agreement_path ||= namespace
    case @namespace_agreement_path
    when "management"
      management_agreement_path(agreement, options)
    else
      collaboration_agreement_path(agreement, options)
    end
  end


  def author_of_agreement?(agreement)
    author_of?(agreement, current_user)
  end

  def agreement_current_editable?(agreement)
    current_user && agreement.editable_by?(current_user)
  end

  def current_moderable_comments?(agreement)
    current_user && agreement.moderable_comments_by?(current_user)
  end  

  def print_correct_date(date)

    if date.year == 9999
      
      "-"
    else
      I18n.localize(date.to_date)
    end
  end

end
