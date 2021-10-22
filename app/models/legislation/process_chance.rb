class Legislation::ProcessChance < ActiveRecord::Base


  include Eventable

  
  belongs_to :process, class_name: 'Legislation::Process', foreign_key: 'legislation_process_id'
  belongs_to :geozone
  scope :public_for_api,           -> { all }
  scope :by_pon_id,    ->(pon_id) { includes(:process).where(:legislation_processes => {:pon_id =>  pon_id}) }


  #STATUS_OPTIONS_WORKS = %w(Programmato Progettazione Gara Cantiere Collaudo Chiuso)


  #validates :work_status, inclusion: { in: STATUS_OPTIONS_WORKS } 

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
      csv << %w{id titolo descrizione data_inizio_lavori data_fine_lavori municipalità zona latitudine longitudine obiettivi benefici rivolto_a stato_avanzamento informazioni_di_contatto indirizzo} 
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
          e.purpose ? e.purpose : "-", 
          e.benefit ? e.benefit : "-",  
          e.addressed_to ? e.addressed_to : "-",  
          e.progress_status ? e.progress_status : "-",  
          e.contacts ? e.contacts : "-",
          e.address ? e.address : "-",  
        ]
      end
    end
  end

end
