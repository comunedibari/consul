module Notifiable
  extend ActiveSupport::Concern

  def notifiable_title
    case self.class.name
    when "ProposalNotification"
      proposal.title
    when "DebateNotification"
      debate.title
    when "Collaboration::AgreementNotification"
      collaboration_agreement.title
    when "CrowdfundingNotification"
      crowdfunding.title
    when "ReportingNotification"  #mia modifica
      reporting.title
    when "Legislation::Question"
      process.title
    when "Comment"
      commentable.title
    when "Event"
      self.title
    when "Asset"
      self.name
    when "BookingManager::ModerableBooking"
      ""
    when "Sector"
      ""
    when "StSector"
      self.name
    when "JobLogs"
      ""
    else
      title
    end
  end

  def notifiable_available?
    case self.class.name
    when "ProposalNotification"
      check_availability(proposal)
    when "DebateNotification"
      check_availability(debate)
    when "CrowdfundingNotification"
      check_availability(crowdfunding)
    when "ReportingNotification"
      check_availability(reporting)
    when Legislation::Process
      check_availability(Legislation::Process)
    when Collaboration::AgreementNotification
      check_availability(Collaboration::Agreement)
    when "Comment"
      check_availability(commentable)
    when "Event"
      check_availability(self)
    when "Asset"
      check_availability_asset(self)
    when "BookingManager::ModerableBooking"
      check_availability_asset(self)
    else
      check_availability(self)
    end
  end

  def check_availability(resource)
    resource.present? &&
      resource.try(:hidden_at).nil? &&
      resource.try(:retired_at).nil?
  end

  def check_availability_asset(resource)
    resource.present? &&
      resource.try(:hidden_at).nil?
  end


  def linkable_resource
    #is_a?(ProposalNotification) ? proposal : self

    #mia inizio
    if is_a?(ProposalNotification)
      proposal
    elsif  is_a?(CrowdfundingNotification)
      crowdfunding
    elsif  is_a?(ReportingNotification)
      reporting
    elsif  is_a?(Collaboration::AgreementNotification)
      collaboration_agreement
    else
      self
    end
    #mia fine

  end
end
