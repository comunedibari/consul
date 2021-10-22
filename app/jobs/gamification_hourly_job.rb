class GamificationHourlyJob < ActiveJob::Base
  
  begin
    include JobLogsHelpers
    queue_as :default
    require 'net/http'
    require 'json'
    require 'sidekiq-scheduler'


    def perform
      log_retryable_job(job_id, nil, self.class.to_s) { 
        sendToEngine()
      }
    end

    private

    def sendToEngine
      logger.info "Execute GamificationServiceResult.assign_badges"
      GamificationServiceResult.assign_badges

      UserAction.unscheduled.each do |action|
        GamificationServiceResult.increse_value(action.user_id,action.gamification_rule.action_service,action.gamification_rule.value)
        #decommentare per segnare come schedulati
        logger.info action.id
        UserAction.setAsScheduled(action.id)
      end
    end
  end
end
