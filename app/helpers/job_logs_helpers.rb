module JobLogsHelpers
    def log_retryable_job(job_id, resource, class_name)
      create_async_job_log(job_id, resource, class_name) unless async_job_log(job_id)
      yield
      mark_job_as_finished(job_id)
    end
    
    def create_async_job_log(job_id, resource, class_name)
      if class_name.to_s == "TagsNotifierJob"
        JobLogs.create(
          jid: job_id,
          state: 'started',
          resource: resource[0].id,
          resource_type: resource[0].class.name,
          job_type: class_name
        )
      elsif class_name.to_s == "DecodeXlsSectorsJob"
        JobLogs.create(
          jid: job_id,
          state: 'started',
          resource: resource[0],
          resource_type: 'file',
          job_type: class_name
        )
      elsif class_name.to_s == "GamificationHourlyJob"
        JobLogs.create(
          jid: job_id,
          state: 'started',
          resource: resource,
          resource_type: 'file',
          job_type: class_name
        )
      elsif class_name.to_s == "GamificationMonthlyJob"
        JobLogs.create(
          jid: job_id,
          state: 'started',
          resource: resource,
          resource_type: 'file',
          job_type: class_name
        )
      elsif class_name.to_s == "ReportingsDataJob"
        JobLogs.create(
          jid: job_id,
          state: 'started',
          resource: resource,
          resource_type: 'file',
          job_type: class_name
        )
      elsif class_name.to_s == "AllReportingsDataJob"
        JobLogs.create(
          jid: job_id,
          state: 'started',
          resource: resource,
          resource_type: 'file',
          job_type: class_name
        )
      else
        JobLogs.create(
          jid: job_id,
          state: 'started',
          resource: resource,
          resource_type: class_name,
          job_type: class_name
        )                
      end 
    end
  
    def async_job_log(job_id)
        JobLogs.find_by(jid: job_id)
    end
  
    def mark_job_as_finished(job_id)
      async_job_log(job_id).finished!
    end
  end