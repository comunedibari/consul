class Legislation::ProcessFinance < ActiveRecord::Base

    belongs_to :process, class_name: 'Legislation::Process', foreign_key: 'legislation_process_id'

  
    #STATUS_OPTIONS_WORKS = %w(Programmato Progettazione Gara Cantiere Collaudo Chiuso)
  
  
    #validates :work_status, inclusion: { in: STATUS_OPTIONS_WORKS } 
  
  end
  