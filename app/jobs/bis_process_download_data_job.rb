class BisProcessDownloadDataJob < ActiveJob::Base
  queue_as :default
  require 'net/http'
  require 'open-uri'
  require 'json'
  require 'sidekiq-scheduler'
  require 'fileutils'
  include JobLogsHelpers
  
  def perform
    log_retryable_job(job_id, nil, self.class.to_s) { 
      count_page()
      #getFromService()
    }
  end

  private

  def loadImage(imgurl, imgtitle, pathId, docLinkable, author)
    begin
      download = open(imgurl)
      fileName = download.base_uri.to_s.split('/')[-1]
      IO.copy_stream(download, pathId + "/" + fileName)
      imgName = ""
      if imgtitle == ''  || imgtitle.mb_chars.length < 4
        imgName = fileName
      else
        imgName = imgtitle
      end
      begin
        Image.create!(title: imgName, attachment: image_file(pathId, fileName), imageable: docLinkable, user: author)    
      rescue
        #raise "ERROR ON DOWNLOADING AND SAVING NEW ATTACHMENT"
        logger.error("ERROR ON DOWNLOADING AND SAVING NEW ATTACHMENT")
        #next
      end
      logger.info "----------FINE SAVING BIS ATTACHMENT----------"
    rescue
    #  raise "ERROR ON DOWNLOADING AND SAVING NEW ATTACHMENT"
      logger.error("ERROR ON DOWNLOADING AND SAVING NEW ATTACHMENT")
    end
  end

  def true?(obj)
    obj.to_s == "true"
  end

  def image_file(path, file_name)
    File.open(path + "/" + file_name)
  end

  def destroyPreviousData(rootDir, dataFromService)
    begin
      legsToCheck = ::Legislation::Process.where(process_type: 2).where(author_id: User.system.id).where("external_id is not null")

      legsToCheck.each do |legProc|
        trovato = false
        dataFromService.each do |singleData|
          #logger.info "---ext id" + legProc.external_id.to_s
          #logger.info "---serv id" + singleData["id"].to_s
          if legProc.external_id === singleData["id"]
            trovato = true
          end
        end
  
        if trovato

          #svuota la cartella degli allegati
          #FileUtils.rm_rf(rootDir)
          pId = legProc.id
          #logger.info "----pid " + pId.to_s
          imgsToDestroy = Image.where(imageable_id: pId)
          imgsToDestroy.each do |imgToDestroy|
            if !imgToDestroy.nil?
              #logger.info "---destroy img "+ imgToDestroy.id.to_s
              imgToDestroy.destroy
            end
          end 

          docsToDestroy = Document.where(documentable_id: pId)
          docsToDestroy.each do |docToDestroy|
            if !docToDestroy.nil?
              docToDestroy.destroy
            end
          end 
        end

        #if !trovato
        #  logger.info "---progetto cancellato ext id " + legProc.external_id.to_s + " chance id " + legProc.id.to_s
        #  legProc.destroy
        #end
        
      end
      logger.info "----------FINE DELETE OLD BIS DATA----------"
    rescue
      raise "ERROR ON DELETING OLD BIS DATA"
      logger.error("ERROR ON DELETING OLD BIS DATA")
    end
  end

  def check_progetto(tMetaData)
    tMetaData == 'single-progetto-template.php'
    #tMetaData["opportunita-obbiettivo-short"] || tMetaData["opportunita-rivolto-short"] || tMetaData["opportunita-benefici-short"] || tMetaData["opportunita-scadenze-short"] || tMetaData["opportunita-obbiettivo"] || tMetaData["opportunita-rivolto"] || tMetaData["opportunita-benefici"] || tMetaData["opportunita-scadenze"] || tMetaData["opportunita-avanzamento"] || tMetaData["opportunita-url-image"] || tMetaData["opportunita-titolo-image"] || tMetaData["opportunita-domanda"] || tMetaData["opportunita-bando"]
  end


  def count_page()
    page_elem = 10
    val = Net::HTTP.get_response(URI.parse("https://www.bariinnovazionesociale.it/wp-json/wp/v2/posts?per_page=#{page_elem}"))
    dati = val.to_hash
    totale = dati['x-wp-total'][0].to_i
    pages = dati['x-wp-totalpages'][0].to_i    
    for i in (1..pages)
      logger.info "----------START PAGINA #{i}----------"
      getFromService(i, page_elem)
      logger.info "----------FINE PAGINA #{i}----------"
    end
  end


  def getFromService(page,page_elem)
    rootDir = "app/assets/images/custom/cm1/bis_attachment_prog/"
    s = Net::HTTP.get_response(URI.parse("https://www.bariinnovazionesociale.it/wp-json/wp/v2/posts?per_page=#{page_elem}&page=#{page}")).body
    begin
      res = JSON.parse(s)
      destroyPreviousData(rootDir, res)
      res.each do |element|
        tMetaData = element["post-meta-fields"]
        template_prj = element["template"]
        if check_progetto(template_prj)
  
          dirPath = rootDir + element["id"].to_s
          idprogetto = element['id'].to_i
          titolo = element['title']['rendered']
          geozona = tMetaData['progetto-municipio'][0].to_i
          descrizione = element['content']['rendered'] == "" ? element['excerpt']['rendered'] : element['content']['rendered']
          if descrizione == ""
            descrizione = "Non disponibile."
          end

          page = Nokogiri::HTML(descrizione)
          tAttachList =  page.css("li").css("img")
          # page.css("li").css("img")[0]["src"]

          tmp = descrizione.split("<div aria-live=\"polite\" id=\"soliloquy-container")
          if tmp.count > 1
            tmp2 = tmp[1].split("{opacity:1}</style></noscript>")
            descrizione = tmp[0]+tmp2[1]
            if tmp.count > 2
              tmp3 = tmp[2].split("{opacity:1}</style></noscript>")
              descrizione = descrizione+tmp3[1]
            end
          end 

          #tAttachList = element["_links"]["wp:attachment"]
          inizioprogetto = Time.parse(element['date']) rescue Time.parse('9999-01-01+01:00')
          fineprogetto = Time.parse('9999-01-01+01:00') #Time.parse(element['date_gmt']) rescue Time.parse('9999-01-01+01:00')
                    
          #blocco legislation_process_works
          costo = tMetaData['progetto-costo'] ? tMetaData["progetto-costo"][0] : ''  #price
          perc_finanziamento = tMetaData['progetto-perc-finanziamento'] ? tMetaData["progetto-perc-finanziamento"][0].to_i : ''  #financing_perc
          
          financing = tMetaData['progetto-finanziamento'][0].to_s #financing

          stato = tMetaData['progetto-stato'][0].to_s #work_status
          
          case stato # a_variable is the variable we want to compare
          when "Realizzazione"
            stato = "Cantiere" 
          when "Completato"
            stato = "Chiuso"
          when ""
            stato = "Programmato"
          else
            stato = stato
          end
          

          address = tMetaData['progetto-indirizzo'][0] #address          
          project_perc = tMetaData['progetto-progettazione'][0] #project_perc
          competition_perc = tMetaData['progetto-gara'][0] #competition_perc
          realizzation_perc = tMetaData['progetto-realizzazione'][0] #realizzation_perc

          #coordinate
          coordiantec_s = tMetaData['progetto-coords'][0] #realizzation_perc "{lat:41.1637882,lng:16.7488748}"
          coordiantec = eval(coordiantec_s)

          #logger.info "---------#{financing}----------"
          FileUtils.mkdir_p dirPath
          pId = nil
          already_exist = ::Legislation::Process.where(external_id: idprogetto).where(hidden_at: nil)
          if already_exist.present? && !already_exist.nil?
            processToUpdate = already_exist[0]
            processToUpdate.title = titolo
            processToUpdate.skip_map = "1"
            processToUpdate.pon_id = User.system.pon_id
            processToUpdate.process_type = 2
            processToUpdate.geozone_id = geozona
            processToUpdate.description = descrizione
            processToUpdate.start_date = inizioprogetto
            processToUpdate.end_date = fineprogetto
            processToUpdate.author_id = User.system.id
            processToUpdate.external_id = idprogetto
            processToUpdate.save
            pId = processToUpdate
            #tAttachList.each do |attach|
            #  parseAttach(attach["href"], dirPath, processToUpdate)
            tAttachList.each do |attach|
              loadImage(attach["src"], attach["alt"], dirPath, processToUpdate, User.system)
            end

            already_exist = ::Legislation::ProcessWork.where(legislation_process_id: pId) #.where(hidden_at: nil)
            if already_exist.present? && !already_exist.nil?
              processWorksToUpdate = already_exist[0]            
              processWorksToUpdate.financing = financing
              processWorksToUpdate.work_status = stato 
              processWorksToUpdate.address = address
              processWorksToUpdate.financing_perc = perc_finanziamento
              processWorksToUpdate.project_perc = project_perc
              processWorksToUpdate.competition_perc = competition_perc
              processWorksToUpdate.realizzation_perc = realizzation_perc
              processWorksToUpdate.save
            else
              ::Legislation::ProcessWork.create!( 
                legislation_process_id: pId.id,
                price: costo,
                financing: financing,
                work_status: stato,
                address: address,
                financing_perc: perc_finanziamento,
                project_perc: project_perc,
                competition_perc: competition_perc,
                realizzation_perc: realizzation_perc
                )            
            end
  
            if !coordiantec.nil?
              already_exist = MapLocation.where(localizable_type: "Legislation::Process").where(localizable_id: pId) #.where(hidden_at: nil)
              if already_exist.present? && !already_exist.nil?
                mapLocationToUpdate = already_exist[0]            
                mapLocationToUpdate.latitude = coordiantec[:lat].to_f
                mapLocationToUpdate.longitude = coordiantec[:lng].to_f
                mapLocationToUpdate.save
              else
                MapLocation.create!(
                  latitude: coordiantec[:lat].to_f,
                  longitude: coordiantec[:lng].to_f,
                  zoom: 9,
                  localizable: pId
                  )            
              end
            end
              
          else
            leg_ext_id = ::Legislation::Process.create!( external_id: idprogetto,
              title: titolo,
              skip_map: "1",
              pon_id: User.system.pon_id,
              process_type: 2,
              geozone_id: geozona,
              description: descrizione,
              start_date: inizioprogetto,
              end_date: fineprogetto,
              author_id: User.system.id,
              debate_start_date: "2019-01-01", 
              debate_end_date: "9999-01-01", 
              debate_phase_enabled: true,
              visible: true
              )

              ::Legislation::ProcessWork.create!( 
                legislation_process_id: leg_ext_id.id,
                price: costo,
                financing: financing,
                work_status: stato,
                address: address,
                financing_perc: perc_finanziamento,
                project_perc: project_perc,
                competition_perc: competition_perc,
                realizzation_perc: realizzation_perc
                )                                 

              if !coordiantec.nil?
                MapLocation.create!(
                  latitude: coordiantec[:lat].to_f,
                  longitude: coordiantec[:lng].to_f,
                  zoom: 9,
                  localizable: leg_ext_id
                  )
              end
                
              SocialContent.create!(
                sociable_id: leg_ext_id.id,
                sociable_type: 'Legislation::Process',
                created_at: leg_ext_id.start_date,
                social_access: TRUE)

            #crea una consultazione iniziale aperta
            question = ::Legislation::Question.create!(legislation_process_id: leg_ext_id.id,
              title: "Discussione iniziale",
              author_id: leg_ext_id.author_id
            )
            #tAttachList.each do |attach|
            #  parseAttach(attach["href"], dirPath, leg_ext_id)
            #end
            tAttachList.each do |attach|
              loadImage(attach["src"], attach["alt"], dirPath, leg_ext_id, User.system)
            end

            pId = leg_ext_id
          end

          #parseMetaData(tMetaData, dirPath, pId, User.system)
          logger.info "Progetto importato - external id: #{idprogetto}"
        else
          logger.info "Non si tratta di un Progetto"
        end
      end
      logger.info "----------FINE INSERT BIS----------"
    rescue
      raise "CANNOT PARSE JSON FROM BIS"
      logger.error("CANNOT PARSE JSON FROM BIS")     
    end
  end

end