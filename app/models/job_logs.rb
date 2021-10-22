class JobLogs < ActiveRecord::Base
  include Notifiable
  
    enum state: {
      started:  1,
      working: 2,
      finished: 3
    }
  end