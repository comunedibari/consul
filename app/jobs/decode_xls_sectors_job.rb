class DecodeXlsSectorsJob < ActiveJob::Base
  queue_as :default
  require 'roo'
  include JobLogsHelpers

  after_perform :notify_manager

  def perform(*file, userC, sector_to_save)
    begin
      log_retryable_job(job_id, file, self.class.to_s) {
        path = File.join(Rails.root, 'app', 'public', 'upload', file)
        roo_open(path, sector_to_save, userC)
        @userToNotify = userC
        @job_id = job_id
      }
    rescue => e
      logger.error "----DecodeXlsSectorsJob error"
      logger.error e.to_s
    end
  end

  private

  def roo_open(file, sectorToSave, userC)
    fileToSave = nil
    trueFormat = false
    case File.extname(file)
    when ".xls"
      fileToSave = Roo::Excel.new(file)
      trueFormat = true
    when ".xlsx"
      fileToSave = Roo::Excelx.new(file)
      trueFormat = true
    end
    if trueFormat
      headers = Hash.new
      fileToSave.row(1).each_with_index { |header, i|
        headers[header] = i
      }

      if checkFile(headers)
        ((fileToSave.first_row + 1)..fileToSave.last_row).each do |row|
          tipologia = fileToSave.row(row)[headers['tipologia']]
          ragione_sociale = fileToSave.row(row)[headers['ragione_sociale']]
          codice_fiscale = fileToSave.row(row)[headers['codice_fiscale']]
          sede_legale = fileToSave.row(row)[headers['sede_legale']]
          email = fileToSave.row(row)[headers['email']]
          telefono = fileToSave.row(row)[headers['telefono']]
          cf_legale_rappresentante = fileToSave.row(row)[headers['cf_legale_rappresentante']]
          #sector_type_name = tipologia.downcase
          #sector_type_idT = SectorType.where("lower(name) = ?", sector_type_name)
          sector_type_idT = sectorToSave.present? && !sectorToSave.nil? ? sectorToSave : 0
          #sector_type_idT[0].id.present? && !sector_type_idT[0].id.nil? ? sector_type_idT[0].id : 0
          already_exist = Sector.where(vat_code: codice_fiscale)
          user_id = User.where(cod_fiscale: cf_legale_rappresentante).first ? User.where(cod_fiscale: cf_legale_rappresentante).first.id : nil
          if User.where(cod_fiscale: cf_legale_rappresentante).first
            legale_rappresentante = User.where(cod_fiscale: cf_legale_rappresentante).first.username
          else
            legale_rappresentante = fileToSave.row(row)[headers['legale_rappresentante']] ? fileToSave.row(row)[headers['legale_rappresentante']].titleize : ''
          end
          #if already_exist.present? && !already_exist.nil?
          if !already_exist.present? || already_exist.nil?
            Sector.create!(
              name: ragione_sociale,
              vat_code: codice_fiscale,
              address: sede_legale,
              legal_representative: legale_rappresentante,
              phone_number: telefono,
              sector_type_id: sector_type_idT,
              cf_rappr_legale: cf_legale_rappresentante,
              user_id: user_id,
              pon_id: userC.pon_id,
              skip_map: "1",
              terms_of_service: "1",
              visible: true,
              email: email)

            id = Sector.where(vat_code: codice_fiscale).first.id
            StSector.create!(
              name: ragione_sociale,
              vat_code: codice_fiscale,
              address: sede_legale,
              legal_representative: legale_rappresentante,
              phone_number: telefono,
              sector_type_id: sector_type_idT,
              cf_rappr_legale: cf_legale_rappresentante,
              user_id: user_id,
              skip_map: "1",
              terms_of_service: "1",
              pon_id: userC.pon_id,
              sector_id: id,
              request: 1,
              state: 2,
              email: email)
          else
            sectorToUpdate = already_exist[0]
            sectorToUpdate.name = ragione_sociale
            sectorToUpdate.vat_code = codice_fiscale
            sectorToUpdate.address = sede_legale
            sectorToUpdate.legal_representative = legale_rappresentante
            sectorToUpdate.phone_number = telefono
            sectorToUpdate.sector_type_id = sector_type_idT
            sectorToUpdate.cf_rappr_legale = cf_legale_rappresentante
            sectorToUpdate.skip_map = "1"
            sectorToUpdate.email = email
            sectorToUpdate.user_id = user_id
            sectorToUpdate.pon_id = userC.pon_id
            sectorToUpdate.save

            StSector.create!(
              name: ragione_sociale,
              vat_code: codice_fiscale,
              address: sede_legale,
              legal_representative: legale_rappresentante,
              phone_number: telefono,
              sector_type_id: sector_type_idT,
              cf_rappr_legale: cf_legale_rappresentante,
              user_id: user_id,
              skip_map: "1",
              terms_of_service: "1",
              pon_id: userC.pon_id,
              sector_id: sectorToUpdate.id,
              request: 2,
              state: 6,
              email: email)
          end
        end
      end
    end
  end

  def checkFile(headers)
    semaph = true
    if headers['tipologia'].nil?
      semaph = false
    end
    if headers['ragione_sociale'].nil?
      semaph = false
    end
    if headers['codice_fiscale'].nil?
      semaph = false
    end
    if headers['sede_legale'].nil?
      semaph = false
    end
    if headers['legale_rappresentante'].nil?
      semaph = false
    end
    if headers['email'].nil?
      semaph = false
    end
    if headers['telefono'].nil?
      semaph = false
    end
    if headers['cf_legale_rappresentante'].nil?
      semaph = false
    end
    return semaph
  end

  def notify_manager
    logger.debug @userToNotify.to_s
    notify
  end

  def notify
    if @userToNotify
      @job = JobLogs.where(jid: @job_id).first
      Notification.add(@userToNotify, @job)
    end
  end

end
