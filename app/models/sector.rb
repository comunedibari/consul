class Sector < ActiveRecord::Base
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
  #include Documentable
  #include Galleryable
  #include Sanitizable
  #include HasPublicAuthor
  #include Imageable
  #include ActsAsParanoidAliases
  #include Relationable

  belongs_to :sector_type, class_name: 'SectorType', foreign_key: 'sector_type_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  has_many :sector_contents, class_name: 'SectorContent'


  scope :sector_type, ->(sector_type) { where("sector_type_id = ?", sector_type) }
  scope :by_user_pon,    -> { where(pon_id: User.pon_id) }
  scope :public_for_api, -> { all }


  #after_save :geolocation_sector



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

  # geolocation for sectors
  def geolocation_sector
    if !self.map_location
      lat = ""
      lon = ""

      begin
        response = RestClient.post 'https://nominatim.openstreetmap.org/?format=json&addressdetails=1&q='+address+'&format=json&limit=1' , {}, {content_type: :json, accept: :json}
        if response.length > 2
          json_response = JSON.parse(response)
          json_response.each do |data|
            lon = data["lon"]
            lat = data["lat"]
          end
        else
          apikey = Rails.application.config.apikey_google
          response = RestClient.post 'https://maps.googleapis.com/maps/api/geocode/json?address='+address+'&key='+apikey , {}, {content_type: :json, accept: :json}

          json_response = JSON.parse(response)

          if json_response["status"].to_s == 'OK'
            lat = json_response["results"][0]["geometry"]["location"]["lat"].to_s
            lon = json_response["results"][0]["geometry"]["location"]["lng"].to_s
          else
            logger.debug "----errore geolocation non disponibile--" + json_response["status"]
          end
        end
        #logger.debug "----geolocation------lat " + lat + " ---lon ---" +lon

        if lat != "" and lon != "" #and 1<0
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
    { name                  => 'A',
      vat_code              => 'A',
      address               => 'B',
      legal_representative  => 'B',
      sector_type.name      => 'C',  #Nota:la chiave di ricerca deve essere un campo testuale e mai un id
      phone_number          => 'D',
      email                 => 'D'
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
