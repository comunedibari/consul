class BisDownloadDataJob < ActiveJob::Base
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


  def parseAttach(attachList, pathId, docLinkable)
    
    begin
      s = Net::HTTP.get_response(URI.parse(attachList)).body
      res = JSON.parse(s)
      author = User.system
      res.each do |element|
        download = open(element["guid"]["rendered"])
        fileName = download.base_uri.to_s.split('/')[-1]
        IO.copy_stream(download, pathId + "/" + fileName)
        imgName = ""
        if element["alt_text"].empty? || element["alt_text"].mb_chars.length < 4
          imgName = fileName
        else
          imgName = element["alt_text"]
        end
        imgName = '-----'
        begin
          #Image.create!(title: imgName, attachment: image_file(pathId, fileName), imageable: docLinkable, user: author)    

          image = File.open(File.join(Rails.root, pathId+"/#{file_name}"))

          Image.create!(
            title: imgName, 
            attachment: image, 
            user: author,
            imageable: docLinkable
            )

        rescue
          next
        end
      end
      logger.info "----------FINE SAVING BIS ATTACHMENT----------"
    rescue
    #  raise "ERROR ON DOWNLOADING AND SAVING NEW ATTACHMENT"
      logger.error("ERROR ON DOWNLOADING AND SAVING NEW ATTACHMENT")
    end
  end

  def parseMetaData(metaList, pathId, docLinkable, author)

    obiettivo = ''
    #obiettivo = metaList["opportunita-obbiettivo"] ? metaList["opportunita-obbiettivo"][0] : ''
    if obiettivo == ''
      obiettivo = metaList["opportunita-obbiettivo-short"] ? metaList["opportunita-obbiettivo-short"][0] : ''
    end

    rivolto = ''
    #rivolto = metaList["opportunita-rivolto"] ? metaList["opportunita-rivolto"][0] : ''
    if rivolto == ''
      rivolto = metaList["opportunita-rivolto-short"] ? metaList["opportunita-rivolto-short"][0] : ''
    end

    benefici = ''
    #benefici = metaList["opportunita-benefici"] ? metaList["opportunita-benefici"][0] : ''
    if benefici == ''
      benefici = metaList["opportunita-benefici-short"] ? metaList["opportunita-benefici-short"][0] : ''
    end

    scadenze = ''
    #scadenze = metaList["opportunita-scadenze"] ? metaList["opportunita-scadenze"][0] : ''
    if scadenze == ''
      scadenze = metaList["opportunita-scadenze-short"] ? metaList["opportunita-scadenze-short"][0] : ''
    end
    
    avanzamento = metaList["opportunita-avanzamento"] ? metaList["opportunita-avanzamento"][0] : ''

    imgurl = metaList["opportunita-url-image"] ? metaList["opportunita-url-image"][0] : ''
    imgtitle = metaList["opportunita-titolo-image"] ? metaList["opportunita-titolo-image"][0] : ''
    domanda =  metaList["opportunita-domanda"] ? metaList["opportunita-domanda"][0] : ''
    bando =  metaList["opportunita-bando"] ? metaList["opportunita-bando"][0] : ''

    info  = ""
    info_d  = ""
    info_b  = ""

    if domanda != ''
      info_d = "<p>Scarica la domanda per partecipare all\'opportunità</p>
      <button class=\"btn btn-outline-primary btn-block\" 
      onclick=\"location.href=\"#{domanda}\"\">
      <i class=\"fa fa-arrow-circle-down \"></i> DOWNLOAD
      </button>"
    end

    p_class=  domanda != '' ? "style=\"margin-top: 30px;\"" : ""
    
    if bando != ''
      info_b = "<p #{p_class}>Scarica il bando sul sito del Comune di Bari</p>
      <button class=\"btn btn-outline-primary btn-block\" 
      onclick=\"location.href=\"#{bando}\"\">
      <i class=\"fa fa-arrow-circle-down \"></i> DOWNLOAD
      </button>"
    end
    
    #info = info_d + info_b
    info = domanda + "-bando-" + bando

    process = nil
    already_exist = ::Legislation::ProcessChance.where(legislation_process_id: docLinkable.id)
    if already_exist.present? && !already_exist.nil?
      processToUpdate = already_exist[0]
      processToUpdate.benefit = benefici
      processToUpdate.addressed_to = rivolto
      processToUpdate.purpose = obiettivo
      processToUpdate.progress_status = avanzamento
      processToUpdate.info = info
      processToUpdate.save
      #utilizzo il campo "additional_info" per salvarmi la scadenza testuale
      docLinkable.additional_info = scadenze
      docLinkable.save
      #process = processToUpdate
    else
      process = ::Legislation::ProcessChance.create!( legislation_process_id: docLinkable.id,
        benefit: benefici,
        addressed_to: rivolto,
        purpose: obiettivo,
        progress_status: avanzamento,
        info: info)
        docLinkable.additional_info = scadenze
        docLinkable.save
    end
    if imgurl != ''
      loadImage(imgurl, imgtitle, pathId, docLinkable, author)
    end
  end

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
      imgName = "-----"
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
      legsToCheck = ::Legislation::Process.where(process_type: 5).where(author_id: User.system.id) #.where(hidden_at: nil)

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
              logger.info "---destroy img "+ imgToDestroy.id.to_s
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
        #  logger.info "---opportunità cancellata ext id " + legProc.external_id.to_s + " chance id " + legProc.id.to_s
        #  legProc.destroy
        #end
      end
      logger.info "----------FINE DELETE OLD BIS DATA----------"
    rescue
      raise "ERROR ON DELETING OLD BIS DATA"
      logger.error("ERROR ON DELETING OLD BIS DATA")
    end
  end

  def check_opportunita(tMetaData)
    tMetaData == 'page-opportunita.php'
    #tMetaData["opportunita-obbiettivo-short"] || tMetaData["opportunita-rivolto-short"] || tMetaData["opportunita-benefici-short"] || tMetaData["opportunita-scadenze-short"] || tMetaData["opportunita-obbiettivo"] || tMetaData["opportunita-rivolto"] || tMetaData["opportunita-benefici"] || tMetaData["opportunita-scadenze"] || tMetaData["opportunita-avanzamento"] || tMetaData["opportunita-url-image"] || tMetaData["opportunita-titolo-image"] || tMetaData["opportunita-domanda"] || tMetaData["opportunita-bando"]
  end

  def count_page()
    page_elem = 1
    val = Net::HTTP.get_response(URI.parse("https://www.bariinnovazionesociale.it/wp-json/wp/v2/pages?per_page=#{page_elem}"))
    dati = val.to_hash
    totale = dati['x-wp-total'][0].to_i
    pages = 11 #dati['x-wp-totalpages'][0].to_i    
    for i in (1..pages)
      logger.info "----------START PAGINA #{i}----------"
      getFromService(i, page_elem)
      logger.info "----------FINE PAGINA #{i}----------"
    end
  end

  def getFromService(page,page_elem)
    rootDir = "app/assets/images/custom/cm1/bis_attachment/"
    s = Net::HTTP.get_response(URI.parse("https://www.bariinnovazionesociale.it/wp-json/wp/v2/pages?per_page=#{page_elem}&page=#{page}")).body  
    begin
      #da tenerere sotto controllo
      #s = s[235..-1]
      res = JSON.parse(s)
      destroyPreviousData(rootDir, res)
      res.each do |element|
        tMetaData = element["post-meta-fields"]
        #if check_opportunita(tMetaData)
        template_opp = element["template"]
        logger.info "---template " + template_opp.to_s
        if check_opportunita(template_opp)
  
          dirPath = rootDir + element["id"].to_s
          idprogetto = element['id'].to_i
          titolo = element['title']['rendered']
          descrizione = element['content']['rendered']

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
          FileUtils.mkdir_p dirPath
          pId = nil
          already_exist = ::Legislation::Process.where(external_id: idprogetto).where(hidden_at: nil)
          if already_exist.present? && !already_exist.nil?
            processToUpdate = already_exist[0]
            processToUpdate.title = titolo
            processToUpdate.skip_map = "1"
            processToUpdate.pon_id = User.system.pon_id
            processToUpdate.process_type = 5
            processToUpdate.description = descrizione
            processToUpdate.start_date = inizioprogetto
            processToUpdate.end_date = fineprogetto
            processToUpdate.author_id = User.system.id
            processToUpdate.external_id = idprogetto
            processToUpdate.save
            pId = processToUpdate
            # tAttachList.each do |attach|
            #   parseAttach(attach["href"], dirPath, processToUpdate)
            tAttachList.each do |attach|
              loadImage(attach["src"], attach["alt"], dirPath, processToUpdate, User.system)            
            end
          else
            leg_ext_id = ::Legislation::Process.create!( external_id: idprogetto,
              title: titolo,
              skip_map: "1",
              pon_id:User.system.pon_id,
              process_type: 5,
              description: descrizione,
              start_date: inizioprogetto,
              end_date: fineprogetto,
              author_id: User.system.id,
              debate_start_date: "2019-01-01", 
              debate_end_date: "9999-01-01", 
              debate_phase_enabled: true,
              visible: true
              )

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
            # tAttachList.each do |attach|
            #   parseAttach(attach["href"], dirPath, leg_ext_id)
            # end
            tAttachList.each do |attach|
              loadImage(attach["src"], attach["alt"], dirPath, leg_ext_id, User.system)
            end
            pId = leg_ext_id
          end
          parseMetaData(tMetaData, dirPath, pId, User.system)
          logger.info "Opportunità importata - external id: #{idprogetto}"
        else
          logger.info "Non si tratta di una Opportunità"
        end
      end
      logger.info "----------FINE INSERT BIS----------"
    rescue
      raise "CANNOT PARSE JSON FROM BIS"
      logger.error("CANNOT PARSE JSON FROM BIS")     
    end
  end

end