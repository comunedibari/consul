module MailerHelper

  def commentable_url(commentable)
    return poll_url(commentable) if commentable.is_a?(Poll)
    return events_url(commentable) if commentable.is_a?(Event)
    return debate_url(commentable) if commentable.is_a?(Debate)
    return proposal_url(commentable) if commentable.is_a?(Proposal)
    return crowdfunding_url(commentable) if commentable.is_a?(Crowdfunding)
    return reporting_url(commentable) if commentable.is_a?(Reporting)
    return community_topic_url(commentable.community_id, commentable) if commentable.is_a?(Topic)
    return budget_investment_url(commentable.budget_id, commentable) if commentable.is_a?(Budget::Investment)
    # Aggiunto: generazione url commentable per patti di collaborazione
    return collaboration_agreement_url(commentable) if commentable.is_a?(Collaboration::Agreement)
    # Aggiunto: generazione url commentable per discussioni su legislation processes
    return legislation_process_question_url(commentable[:legislation_process_id], commentable[:id]) if commentable.is_a?(Legislation::Question)
  end

end
