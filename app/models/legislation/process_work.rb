class Legislation::ProcessWork < ActiveRecord::Base

  include Rails.application.routes.url_helpers
  include Eventable


  belongs_to :process, class_name: 'Legislation::Process', foreign_key: 'legislation_process_id'
 
  scope :public_for_api,           -> { all }
  scope :by_pon_id,    ->(pon_id) { includes(:process).where(:legislation_processes => {:pon_id =>  pon_id}) }

  STATUS_OPTIONS_WORKS = %w(Programmato Progettazione Finanziamento Gara Cantiere Collaudo Chiuso)


  validates :work_status, inclusion: { in: STATUS_OPTIONS_WORKS } 

  #validates  :work_status_finish,  presence: true 

  def title
    process.title
  end

  def start_date
    process.start_date
  end

  def end_date
    process.end_date
  end

  def description
    process.description
  end

  def author
    process.author
  end


  def self.to_csv
    CSV.generate(:col_sep => ";") do |csv|
      csv << %w{id titolo descrizione data_inizio_lavori data_fine_lavori municipalità zona latitudine longitudine costo_lavori finanziamento stato_lavori indirizzo informazioni_di_contatto avanzamento_finanziamento avanzamento_progetto avanzamento_gara avanzamento_realizzazione} 
      all.each do |e|
        csv << [
          e.process.id, 
          e.process.title,
          e.process.description, 
          e.process.start_date.strftime('%Y-%m-%d %H:%M:%S'), 
          e.process.end_date.strftime('%Y-%m-%d %H:%M:%S'), 
          e.process.pon.name,
          e.process.geozone ? e.process.geozone.name : nil,
          e.process.map_location ? e.process.map_location.latitude : nil, 
          e.process.map_location ? e.process.map_location.longitude : nil,
          e.price ? e.price : "-", 
          e.financing ? e.financing : "-",  
          e.work_status ? e.work_status : "-",  
          e.address ? e.address : "-",  
          e.contacts ? e.contacts : "-",  
          e.financing_perc ? e.financing_perc : "-",  
          e.project_perc ? e.project_perc : "-",  
          e.competition_perc ? e.competition_perc : "-",  
          e.realizzation_perc ? e.realizzation_perc : "-", 
        ]
      end
    end
  end



=begin  def work_status_finish 
    if( (work_status == 'Chiuso') && (financing_perc != 100) && (project_perc != 100) && (competition_perc != 100) && (realizzation_perc != 100) )
      errors.add(:work_status, I18n.t('admin.legislation.processes_work.edit.work_status_finish.error'))
      render :edit
      return false
    else
      return true
    end
  end
=end



  
end
