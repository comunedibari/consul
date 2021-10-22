class RecoverTagNotificationsJob < ActiveJob::Base
  queue_as :default
  include JobLogsHelpers
  include NotificationsHelper

  def perform
    jobToRePerform = JobLogs.where.not(state: 3).where(job_type: 'TagsNotifierJob')
    if(jobToRePerform.length != 0)
      recreateJob(jobToRePerform)
    end
  end

  private

  def recreateJob(jobToRePerform)
    jobToRePerform.each do |job|
      resource = nil
      case job.resource_type
      when "Debate"
          resource = Debate.with_hidden.find(job.resource)
          mark_job_as_finished job.jid
          send_notification_for_tags(resource)
      when "Proposal"
          resource = Proposal.with_hidden.find(job.resource)
          mark_job_as_finished job.jid
          send_notification_for_tags(resource)
      when "Crowdfunding"
        resource = Crowdfunding.with_hidden.find(job.resource)
        mark_job_as_finished job.jid
        send_notification_for_tags(resource)
      when "Legislation::Process"
          resource = Legislation::Process.with_hidden.find(job.resource)
          mark_job_as_finished job.jid
          send_notification_for_tags(resource)
      when "Event"
          resource = Event.with_hidden.find(job.resource)
          mark_job_as_finished job.jid
          send_notification_for_tags(resource)
      when "Asset"
        resource = Asset.with_hidden.find(job.resource)
        mark_job_as_finished job.jid
        send_notification_for_tags(resource)
      when "BookingManager::ModerableBooking"
        resource = BookingManager::ModerableBooking.with_hidden.find(job.resource)
        mark_job_as_finished job.jid
        send_notification_for_tags(resource)     
      end
    end
  end
end