class AllReportingsDataJob < ActiveJob::Base
  queue_as :default
  require 'net/http'
  require 'open-uri'
  require 'json'
  require 'sidekiq-scheduler'
  require 'fileutils'
  include JobLogsHelpers
  
  def perform
    log_retryable_job(job_id, nil, self.class.to_s) { 
      #count_page()
      get_reportings_from_url()
    }
  end

  private

  def get_reportings_from_url

    rootDir = "app/assets/images/custom/cm1/reporting_attachment/"
    
    begin
      response = RestClient.post 'https://esb.comune.bari.it/cdb-restful-ws-v2/bareport/segnalazioni' , {}, {content_type: :json, accept: :json}
      
      json_response = JSON.parse(response)
      #destroyPreviousData(rootDir, json_response)
      
      json_response["segnalazioni"].each do |item|
        user = User.system
        map_loc = MapLocation.new()
        user.username = item["username"]
        rep_type = ReportingType.where(nome: item["tipoDescrizione"]).first
        
        url_preview = item["foto"].strip
        if url_preview.end_with?(".it")
          url_preview = nil
        end
        
        nota = item["nota"]
        if nota == "null" || nota.blank?
          nota = ""
        end
        
        titolo = item["titolo"]
        if titolo == "null" || titolo.blank?
          titolo = "Titolo non inserito"
        end
        idSegnalazione = item["idSegnalazione"].to_i 
        
        already_exist = Reporting.where(external_id: idSegnalazione)

        if already_exist.present? && !already_exist.nil?
          reportingToUpdate = already_exist[0]
          if reportingToUpdate.description_status != item["statoDescrizione"] or reportingToUpdate.note != nota
            #reportingToUpdate.address = item["indirizzo"]
            #reportingToUpdate.title = titolo
            #reportingToUpdate.created_at = item["data"]
            #reportingToUpdate.author = user
            #reportingToUpdate.reporting_type = rep_type
            reportingToUpdate.description_status = item["statoDescrizione"]
            reportingToUpdate.note = nota
            #reportingToUpdate.description = item["descrizione"]
            #reportingToUpdate.url_image_preview = url_preview
            #reportingToUpdate.skip_map = "1"
            #reportingToUpdate.external_id = item["idSegnalazione"]
            #reportingToUpdate.terms_of_service = "1"
            #reportingToUpdate.pon = Pon.all.where(id: 5).sample
            reportingToUpdate.save
          end         
        else
          rep = Reporting.create!(
            address: item["indirizzo"],
            title: titolo,
            created_at: item["data"],
            author: user,
            reporting_type: rep_type,
            description_status: item["statoDescrizione"],
            note: nota,
            description: item["descrizione"],
            #url_image_preview: url_preview,
            skip_map: "1",
            external_id: item["idSegnalazione"],
            terms_of_service: "1",
            moderation_entity: 1,
            pon: Pon.all.where(id: 5).sample
          )

          SocialContent.create!(
            sociable_id: rep.id,
            sociable_type: 'Reporting',
            created_at: rep.created_at,
            social_access: TRUE) 
        
          map_loc = MapLocation.create!(
            localizable_id: rep.id,
            localizable_type: "Reporting",
            latitude: item["latitudeX"].to_f,
            longitude:  item["longitudeY"].to_f,
            zoom: 9
            )   

          #dirPath = rootDir + idSegnalazione.to_s
          dirPath = "app/assets/images/custom/cm1/reporting_attachment/"
          if item["foto"] != 'https://esb.comune.bari.it'
            loadImage(item["foto"], "Foto", dirPath, rep, User.system)
          end

        end

      end
    rescue SocketError => e
     render action: "show_esb_error"
    rescue => e
      logger.error "----------In Socket errror"
      raise
    rescue RestClient::Exception => e
      logger.error e.http_body
    end 
  end

  def image_file(path, file_name)
    File.open(path + "/" + file_name)
  end

  def loadImage(imgurl, imgtitle, pathId, docLinkable, author)
    begin
      download = open(imgurl)
      #logger.info "----------URL ATTACHMENT----------#{imgurl}"
      fileName = download.base_uri.to_s.split('/')[-1]
      #logger.info "----------NAME ATTACHMENT----------#{fileName}"
      #logger.info "----------PATH ATTACHMENT----------#{pathId}"
      IO.copy_stream(download, pathId + "/" + fileName)
      #logger.info "----------COPY ATTACHMENT----------#{pathId}"
      imgName = ""
      if imgtitle == ''  || imgtitle.mb_chars.length < 4
        imgName = fileName
      else
        imgName = imgtitle
      end
      #imgName = "-----"
      
      image = File.open(File.join(Rails.root, pathId+"/#{fileName}"))
      #logger.info "----------open ATTACHMENT----------#{Rails.root}"
      begin

        Image.create!(
          title: imgName, 
          attachment: image, 
          user: author,
          imageable: docLinkable
        )

      rescue
        #raise "ERROR ON DOWNLOADING AND SAVING NEW ATTACHMENT"
        logger.error("ERROR ON DOWNLOADING AND SAVING NEW IMAGE")
        #next
      end
      logger.info "----------FINE SAVING REPORTING ATTACHMENT----------"
    rescue
      #raise "ERROR ON DOWNLOADING AND SAVING NEW ATTACHMENT"
      logger.error("ERROR ON DOWNLOADING AND SAVING NEW ATTACHMENT")
    end
  end

end