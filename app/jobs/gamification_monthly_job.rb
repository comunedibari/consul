class GamificationMonthlyJob < ActiveJob::Base
  

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
      logger.info "GamificationMonthlyJob"
      GamificationResult.all.each do |result|
        GamificationResult.all.update_stats(result.id)
      end
      GamificationServiceResult.all.each do |serviceResult|
        GamificationServiceResult.update_stats(serviceResult.id)
      end
    end
  end
end
