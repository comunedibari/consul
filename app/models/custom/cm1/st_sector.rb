class StSector < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  include Mappable
  include Flaggable
  include Conflictable
  include Measurable
  include Searchable
  include Filterable
  include Graphqlable
  include Notifiable

  #include Communitable
  include Documentable
  #include Galleryable
  #include Sanitizable
  #include HasPublicAuthor
  include Imageable
  #include ActsAsParanoidAliases
  include Relationable

  belongs_to :sector_type, class_name: 'SectorType', foreign_key: 'sector_type_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  has_many :sector_contents, class_name: 'SectorContent'
  belongs_to :sector, class_name: 'Sector', foreign_key: 'sector_id'

  belongs_to :pon

  scope :sector_type, ->(sector_type) { where("sector_type_id = ?", sector_type) }
  scope :by_user_pon, -> { where(pon_id: User.pon_id) }
  scope :public_for_api, -> { all }
  scope :sort_by_created_at, -> { reorder(created_at: :desc) }

  validates :terms_of_service, acceptance: { allow_nil: false }, on: :create
  validates :name, presence: true


  #after_save :geolocation_sector

=begin
  --- Macchina a stati ---
  request (integer):
  1 = Inserimento
  2 = Modifica
  3 = Cancellazione
  4 = Subentro

  state (integer):
  1 = In approvazione
  2 = Approvata
  3 = Non approvata
  4 = Integrazioni
  5 = Modifica in approvazione
  6 = Modifica approvata
  7 = Modifica negata
  8 = Cancellazione in approvazione
  9 = Cancellazione negata
  10 = Cancellazione approvata
  11 = Integrazioni
  12 = Legale rappresentante rimosso
  13 = Legale rappresentante aggiornato

status_edit (integer):
  1 = Padre
  2 = Figlio
=end

  enum state: { "In approvazione" => 1, "Approvata" => 2, "Non approvata" => 3, "Richiesta di integrazione" => 4, "In approvazione " => 5,
                "Approvata " => 6, "Non approvata " => 7, "In approvazione  " => 8, "Non approvata  " => 9, "Approvata  " => 10, "Richiesta di integrazione " => 11,
                "Legale rappresentante rimosso" => 12, "Legale rappresentante aggiornato" => 13}

  enum request: { "Inserimento" => 1, "Modifica" => 2, "Cancellazione" => 3, "Subentro" => 4 }

  def editable_by?(user, s_id)
    if (user_id == user.id)
      id = StSector.where(sector_id: s_id).maximum(:id)
      st_sector = StSector.where(id: id).first
      if [2, 4, 6, 7, 9, 13].include? StSector.states[st_sector.state]
        true
      else
        false
      end
    else
      false
    end
  end

  def editable_by_with_st?(user, s_id, st)
    if (user_id == user.id)
      st_sector = StSector.where(sector_id: s_id).where(id: st).first
      if st_sector.nil?
        false
      elsif [2, 4, 6, 13].include? StSector.states[st_sector.state]
        id = StSector.where(sector_id: s_id).where(state: [2, 4, 6, 13, 5, 8]).maximum(:id)
        id == st_sector.id
      else
        false
      end
    else
      false
    end
  end

  def cleanable_by?(user, s_id)
    if (user_id == user.id)
      id = StSector.where(sector_id: s_id).maximum(:id)
      st_sector = StSector.where(id: id).first
      if StSector.states[st_sector.state] == 5
        true
      else
        false
      end
    else
      false
    end
  end

  def creable_by?(user)
    if user.is_spid?
      true
    end
  end

  def visible_by?(user, sector)
    if user_id == user.id || sector.sector.visible == true
      true
    else
      false
    end
  end

  def self.to_csv
    CSV.generate(:col_sep => ";") do |csv|
      csv << %w{ id nominativo partita_iva_cod_fiscale indirizzo rappresentate_legale numero_telefono email tipologia_terzo_settore}
      all.each do |e|
        csv << [
          e.id,
          e.name,
          e.vat_code,
          e.address,
          e.legal_representative,
          e.phone_number,
          e.email,
          e.sector_type.name
        ]
      end
    end
  end

  documentable max_documents_allowed: 3,
               max_file_size: 3.megabytes #,
  #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
  #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
  imageable max_images_allowed: 1

  # geolocation for sectors
  def geolocation_sector
    if !self.map_location
      lat = ""
      lon = ""

      begin
        response = RestClient.post 'https://nominatim.openstreetmap.org/?format=json&addressdetails=1&q=' + address + '&format=json&limit=1', {}, { content_type: :json, accept: :json }
        if response.length > 2
          json_response = JSON.parse(response)
          json_response.each do |data|
            lon = data["lon"]
            lat = data["lat"]
          end
        else
          apikey = Rails.application.config.apikey_google
          response = RestClient.post 'https://maps.googleapis.com/maps/api/geocode/json?address=' + address + '&key=' + apikey, {}, { content_type: :json, accept: :json }

          json_response = JSON.parse(response)

          if json_response["status"].to_s == 'OK'
            lat = json_response["results"][0]["geometry"]["location"]["lat"].to_s
            lon = json_response["results"][0]["geometry"]["location"]["lng"].to_s
          else
            logger.debug "----errore geolocation non disponibile--" + json_response["status"]
          end
        end
        #logger.debug "----geolocation------lat " + lat + " ---lon ---" +lon

        if lat != "" and lon != "" #and 1 < 0
          MapLocation.create!(
            latitude: lat,
            longitude: lon,
            zoom: 9,
            localizable: self
          )
        end
        #inserimento dati casuali per test
=begin
        MapLocation.create!(
          latitude: rand(41.11836..41.12399),
          longitude: rand(16.85415..16.86998),
          zoom: 9,
          localizable: self
        )
=end
      rescue SocketError => e
        logger.error "----------In Socket errror" + e.to_s
        #raise
      rescue => e
        logger.error "----------In Socket errror" + e.to_s
        #raise
      end
    end
  end

  def searchable_values
    { name => 'A',
      vat_code => 'A',
      address => 'B',
      legal_representative => 'B',
      sector_type.name => 'C', #Nota:la chiave di ricerca deve essere un campo testuale e mai un id
      phone_number => 'D',
      email => 'D'
    }
  end

  def self.search(terms)
    pg_search(terms)
  end

  def crea_relation_sector(user_sel)
    update_attribute(:user_id, user_sel.id)
    update_attribute(:cf_rappr_legale, user_sel.cod_fiscale)
    update_attribute(:legal_representative, user_sel.username)
  end

  def del_relation_sector
    update_attribute(:user_id, nil)
    update_attribute(:cf_rappr_legale, "")
    update_attribute(:legal_representative, "")
  end

end
