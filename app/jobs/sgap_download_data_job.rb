class SgapDownloadDataJob < ActiveJob::Base
  queue_as :default
  require 'net/http'
  require 'open-uri'
  require 'json'
  require 'active_support/core_ext/hash'
  require 'sidekiq-scheduler'
  include JobLogsHelpers

  def perform
    log_retryable_job(job_id, nil, self.class.to_s) { 
      getProgettazione()
      getFaseProgetto()
      getFinanziamento()
    }
  end

  private

  def getProgettazione()
    s = Net::HTTP.get_response(URI.parse('https://esb.comune.bari.it/services/da_progettazioneProxyService')).body
    begin
      xmlToJS = Hash.from_xml(s).to_json
      xmlToJS = JSON.parse(xmlToJS)
      entry = xmlToJS['Entries']['Entry']
      entry.each do |element|
        idprogetto = element['idprogetto'].to_i
        titolo = element['titolo']
        description = ' '
        progettosospeso = element['progettosospeso'].to_s == 'true' ? true : false
        importofinanziato = element['importofinanziato'].to_f
        importobaseasta = element['importobaseasta'] .to_f
        importorealizzato = element['importorealizzato'].to_f
        importodarealizzare = element['importodarealizzare'].to_f
        inizioprogetto = Time.parse(element['inizioprogetto']) rescue Time.parse('9999-01-01+01:00')
        fineprogetto = Time.parse(element['fineprogetto']) rescue Time.parse('9999-01-01+01:00')
        importosal = element['importosal'].to_f
=begin        logger.info "----------INIZIO ENTRY PROGETTAZIONE----------"
        logger.info "idprogetto: #{idprogetto} #{idprogetto.class}"
        logger.info "titolo: #{titolo} #{titolo.class}"
        logger.info "progettosospeso: #{progettosospeso} #{progettosospeso.class}"
        logger.info "importofinanziato: #{importofinanziato} #{importofinanziato.class}"
        logger.info "importobaseasta: #{importobaseasta} #{importobaseasta.class}"
        logger.info "importorealizzato: #{importorealizzato} #{importorealizzato.class}"
        logger.info "importodarealizzare: #{importodarealizzare} #{importodarealizzare.class}"
        logger.info "inizioprogetto: #{inizioprogetto} #{inizioprogetto.class}"
        logger.info "fineprogetto: #{fineprogetto} #{fineprogetto.class}"
        logger.info "importosal: #{importosal} #{importosal.class}"
        logger.info "----------FINE ENTRY PROGETTAZIONE----------"
=end        
        already_exist = ::Legislation::Process.where(external_id: idprogetto)
        if already_exist.present? && !already_exist.nil?
          processToUpdate = already_exist[0]
          pId = processToUpdate.id
          processToUpdate.title = titolo
          processToUpdate.start_date = inizioprogetto
          processToUpdate.end_date = fineprogetto
          processToUpdate.external_id = idprogetto
          processToUpdate.save
          pTUSgap = ::Legislation::ProcessSgap.where(legislation_process_id: pId)
          processSgapToUpdate = pTUSgap[0]
          processSgapToUpdate.progettosospeso = progettosospeso
          processSgapToUpdate.importofinanziato = importofinanziato
          processSgapToUpdate.importobaseasta = importobaseasta
          processSgapToUpdate.importorealizzato = importorealizzato
          processSgapToUpdate.importodarealizzare = importodarealizzare
          processSgapToUpdate.inizioprogetto = inizioprogetto
          processSgapToUpdate.fineprogetto = fineprogetto
          processSgapToUpdate.importosal = importosal
          processSgapToUpdate.save
        else
          leg_ext_id = ::Legislation::Process.create!( external_id: idprogetto,
                                          title: titolo,
                                          description: description,
                                          skip_map: "1",
                                          pon_id:User.system.pon_id,
                                          process_type: 4,
                                          start_date: inizioprogetto,
                                          end_date: fineprogetto,
                                          author_id: User.system.id,
                                          debate_start_date: "2019-01-01", 
                                          debate_end_date: "9999-01-01", 
                                          debate_phase_enabled: true,
                                          visible: false
                                          )
          ::Legislation::ProcessSgap.create!(
            legislation_process_id: leg_ext_id.id, 
            progettosospeso: progettosospeso,                
            importofinanziato: importofinanziato,
            importobaseasta: importobaseasta,
            importorealizzato: importorealizzato,
            importodarealizzare: importodarealizzare,
            inizioprogetto: inizioprogetto,              
            fineprogetto: fineprogetto,
            importosal: importosal
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

        end
      end
      logger.info "----------FINE INSERT OR UPDATE PROGETTAZIONE----------"
    rescue
      raise "CANNOT PARSE JSON FROM PROGETTAZIONE"
      logger.error("CANNOT PARSE JSON FROM PROGETTAZIONE")
    end
  end

  def true?(obj)
    obj.to_s == "true"
  end

  def getFaseProgetto()
    s = Net::HTTP.get_response(URI.parse('https://esb.comune.bari.it/services/sgap_fase_progettoProxyService')).body
    begin
      xmlToJS = Hash.from_xml(s).to_json
      xmlToJS = JSON.parse(xmlToJS)
      entry = xmlToJS['Entries']['Entry']
      entry.each do |element|
        id = element['Id'].to_i
        code = element['Code']
        description = (element['Description'].include? 'xsi:nil')? nil : element['Description']

        idAlice = element['IdAlice'].to_i
        dataInizioPrevista = Time.parse(element['DataInizioPrevista']) rescue Time.parse('9999-01-01+01:00')
        dataFinePrevista = Time.parse(element['DataFinePrevista']) rescue Time.parse('9999-01-01+01:00')
        dataInizioEffettiva = Time.parse(element['DataInizioEffettiva']) rescue Time.parse('9999-01-01+01:00')
        dataFineEffettiva = Time.parse(element['DataFineEffettiva']) rescue Time.parse('9999-01-01+01:00')
        progetto = element['Progetto'].to_i
=begin        logger.info "----------INIZIO ENTRY FASE PROGETTO----------"
        logger.info "Id: #{id}"
        logger.info "Code: #{code}"
        logger.info "Description: #{description}"
        logger.info "IdAlice: #{idAlice}"
        logger.info "DataInizioPrevista: #{dataInizioPrevista}"
        logger.info "DataFinePrevista: #{dataFinePrevista}"
        logger.info "DataInizioEffettiva: #{dataInizioEffettiva}"
        logger.info "DataFineEffettiva: #{dataFineEffettiva}"
        logger.info "Progetto: #{progetto}"
        logger.info "----------FINE ENTRY FASE PROGETTO----------"
=end
        already_exist = ::Legislation::ProcessPhase.where(id_phase: id)
        if already_exist.present? && !already_exist.nil?
          phaseToUpdate = already_exist[0]
          phaseToUpdate.id_phase = id
          phaseToUpdate.code = code
          phaseToUpdate.description = description
          phaseToUpdate.idalice = idAlice
          phaseToUpdate.datainizioprevista = dataInizioPrevista
          phaseToUpdate.datafineprevista = dataFinePrevista
          phaseToUpdate.datainizioeffettiva = dataInizioEffettiva
          phaseToUpdate.datafineeffettiva = dataFineEffettiva
          phaseToUpdate.save
        else
          leg_proc = ::Legislation::Process.where(external_id: progetto)
          leg_proc = leg_proc[0]
          ::Legislation::ProcessPhase.create!(
            legislation_process_id: leg_proc.id, 
            code: code,                
            description: description,
            idalice: idAlice,
            datainizioprevista: dataInizioPrevista,
            datafineprevista: dataFinePrevista,
            datainizioeffettiva: dataInizioEffettiva,
            datafineeffettiva: dataFineEffettiva,
            id_phase: id
            )
        end        
      end
      logger.info "----------FINE INSERT OR UPDATE FASE PROGETTAZIONE----------"
    rescue
      raise "CANNOT PARSE JSON FROM FASI"
      logger.error("CANNOT PARSE JSON FROM FASI")
    end
  end

  def getFinanziamento()
    s = Net::HTTP.get_response(URI.parse('https://esb.comune.bari.it/services/sgap_finanziamentoProxyService')).body
    begin
      xmlToJS = Hash.from_xml(s).to_json
      xmlToJS = JSON.parse(xmlToJS)
      entry = xmlToJS['Entries']['Entry']
      entry.each do |element|
        id = element['Id'].to_i
        code = element['Code'].to_i
        desc = element['Description']
        amount = element['Importo'].to_f
        action = (element['EstremiProvvedimento'].include? 'xsi:nil')? nil : element['EstremiProvvedimento']
        id_alice = element['IdAlice']
        id_progetto = element['Progetto']
=begin        logger.info "----------INIZIO ENTRY FINANZIAMENTO PROGETTO----------"
        logger.info "Id: #{id}"
        logger.info "Code: #{code}"
        logger.info "Description: #{desc}"
        logger.info "Importo: #{amount}"
        logger.info "EstremiProvvedimento: #{action}"
        logger.info "Progetto: #{id_progetto}"
        logger.info "IdAlice: #{id_alice}"
        logger.info "----------FINE ENTRY FINANZIAMENTO PROGETTO----------"
=end
        already_exist = ::Legislation::ProcessFinance.where(id_finance: id)
        if already_exist.present? && !already_exist.nil?
          financeToUpdate = already_exist[0]
          financeToUpdate.id_finance = id
          financeToUpdate.code = code
          financeToUpdate.description = desc
          financeToUpdate.amount = amount
          financeToUpdate.action = action
          financeToUpdate.id_alice = id_alice
          financeToUpdate.save
        else
          leg_proc = ::Legislation::Process.where(external_id: id_progetto)
          leg_proc = leg_proc[0]
          ::Legislation::ProcessFinance.create!(
            id_finance: id,                
            code: code,
            description: desc,
            amount: amount,
            action: action,
            id_alice: id_alice,
            legislation_process_id: leg_proc.id
            )
        end
      end
      logger.info "----------FINE INSERT OR UPDATE FINANZIAMENTO PROGETTAZIONE----------"
    rescue
      raise "CANNOT PARSE JSON FROM FINANZIAMENTO"
      logger.error("CANNOT PARSE JSON FROM FINANZIAMENTO")
    end
  end
end
