class Reporting < ActiveRecord::Base
    include Rails.application.routes.url_helpers
    include Flaggable
    include Taggable
    include Conflictable
    include Measurable
    include Sanitizable
    include Searchable
    include Filterable
    include HasPublicAuthor
    include Graphqlable
    include Followable
    include Communitable
    include Imageable
    include Mappable
    include Notifiable
    include Documentable
    include Galleryable
    include Moderable
    include Sectorable
    include Sociable


    documentable max_documents_allowed: 10,
              max_file_size: 3.megabytes#,
              #accepted_content_types: [ "application/pdf","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/msword"],
              #extension_content_types: ["pdf","docx","doc"] #Setting["extension_content_types",User.pon_id].split(",")
    imageable max_images_allowed: 1
    include EmbedVideosHelper
    include Relationable

    #commentata io
    #acts_as_votable

    acts_as_paranoid column: :hidden_at
    include ActsAsParanoidAliases
    MAX_LENGTH_TITLE = 255

    RETIRE_OPTIONS = %w(duplicated started unfeasible done other)

    if Rails.application.config.cm == 'cm1'
      STATUS_OPTIONS = %w(Inoltrata In\ lavorazione Chiusa Risolta)
    else
      STATUS_OPTIONS = %w(Aperto In\ corso Chiuso)
    end

    belongs_to :pon
    scope :by_user_pon,              -> { where(pon_id: User.pon_id)}


    #miaaa
    #scope :reporting_type_scope,     -> (reporting_type) { where(reporting_type_id: reporting_type)} #mia
    #scope :reporting_type_scope,     -> (reporting_type) { joins(:reporting_type).where("reportings.nome = ?" ,reporting_type) } #mia

    belongs_to :author, -> { with_hidden }, class_name: 'User', foreign_key: 'author_id'
    belongs_to :geozone
    belongs_to :reporting_type, class_name: 'ReportingType', foreign_key: 'reporting_type_id'

    has_many :comments, as: :commentable, dependent: :destroy
    #commento io
    # has_many :votes, as: :votable
    has_many :reporting_notifications, dependent: :destroy

    has_one :institution

    # validates :title,
    validates :author, presence: true
    validates :pon, presence: true
    #validates :responsible_name, presence: true

    #validates :images, presence: true
    #validates :map_location, presence: true

    validate :map_location_from_local
    validate :images_from_local

    validates :title, presence: true
    validates :description, length: { maximum: Reporting.description_max_length } #, presence: true
    validates :note, length: { in: 0..Reporting.description_max_length }
    #validates :responsible_name, length: { in: 6..Reporting.responsible_name_max_length }
    validates :retired_reason, inclusion: { in: RETIRE_OPTIONS, allow_nil: true }

    #mia
    validates :description_status, inclusion: { in: STATUS_OPTIONS }
    validates :terms_of_service, acceptance: { allow_nil: false }, on: :create

    validate :valid_video_url?

    #validates :reporting_type, presence: true  #miaa


    before_validation :set_responsible_name

    before_save :calculate_hot_score, :calculate_confidence_score

    scope :for_render,               -> { includes(:tags) }
    scope :sort_by_hot_score,        -> { reorder(hot_score: :desc) }
    scope :sort_by_confidence_score, -> { reorder(confidence_score: :desc) }
    scope :sort_by_created_at,       -> { reorder(created_at: :desc) }
    scope :sort_by_most_commented,   -> { reorder(comments_count: :desc) }
    scope :sort_by_random,           -> { reorder("RANDOM()") }
    scope :sort_by_relevance,        -> { all }
    scope :sort_by_flags,            -> { order(flags_count: :desc, updated_at: :desc) }
    scope :sort_by_archival_date,    -> { archived.sort_by_confidence_score }
#commento mio
    #scope :sort_by_recommendations,  -> { order(cached_votes_up: :desc) }


    scope :sort_by_all,              -> { all.reorder(created_at: :desc) }
    scope :sort_by_forward,          -> { where(description_status: "Inoltrata").reorder(created_at: :desc) }
    scope :sort_by_closed,          -> { where(description_status: "Chiusa").reorder(created_at: :desc) }
    scope :sort_by_at_work,          -> { where(description_status: "In lavorazione").reorder(created_at: :desc) }
    scope :sort_by_resolved,          -> { where(description_status: "Risolta").reorder(created_at: :desc) }

    scope :archived,                 -> { where("reportings.created_at <= ?", Setting["months_to_archive_reportings",User.pon_id].to_i.months.ago) }
    scope :not_archived,             -> { where("reportings.created_at > ?", Setting["months_to_archive_reportings",User.pon_id].to_i.months.ago) }
    scope :last_week,                -> { where("reportings.created_at >= ?", 7.days.ago)}
    scope :retired,                  -> { where.not(retired_at: nil) }
    scope :not_retired,              -> { where(retired_at: nil) }
#commento mio
    scope :successful,               -> { where("cached_votes_up >= ?", Reporting.votes_needed_for_success) }
 #   scope :unsuccessful,             -> { where("cached_votes_up < ?", Reporting.votes_needed_for_success) }
    scope :public_for_api,           -> { all.mod_approved }
# commento io
#  scope :not_supported_by_user,    ->(user) { where.not(id: user.find_voted_items(votable_type: "Reporting").compact.map(&:id)) }

#    def save
#      if self.valid?
#        true
#      else
#        false
#      end
#    end


    #attr_accessor :url_image_preview

    def self.max_length_title
      120
    end

    def self.current_id
      1
    end

    def url
      reporting_path(self)
    end

    def url_new
     reporting_path(self)
    end

    def creable_by?(user)
      # se sei un utente social e se il servizio è attivo per utenti social

      social_service = Setting.where(key: 'service_social.reportings').where("value = 'true' ").where(pon_id: user.pon_id).first

      if !user.can_create?
        return false
      end
      if user.provider.present? && user.is_social? && !social_service #se sono social e non è attivo il servizio per i social
        return false
      end

      return true  #se sono spid oppure se cono social ed è attivo il servizio per i social

    end

    def self.recommendations(user)
      tagged_with(user.interests, any: true)
        .where("author_id != ?", user.id)
        .unsuccessful
        .not_followed_by_user(user)
        .not_archived
        .not_supported_by_user(user)
    end

    def self.not_followed_by_user(user)
      where.not(id: followed_by_user(user).pluck(:id))
    end

    def to_param
      "#{id}-#{title}".parameterize
    end

    def searchable_values
      { title              => 'A',
        question           => 'B',
        author.username    => 'B',
        tag_list.join(' ') => 'B',
        geozone.try(:name) => 'B',
        summary            => 'C',
        description        => 'D',
      }
    end

    def self.search(terms)
     # logger.debug "------------ search"+terms
      by_code = search_by_code(terms.strip)
      #logger.debug "-------"+by_code.to_s
      by_code.present? ? by_code : pg_search(terms)
    end

    def self.search_by_code(terms)
      #logger.debug "------------ code--"+terms
      matched_code = match_code(terms)
      results = where(id: matched_code[1]) if matched_code
      return results if results.present? && results.first.code == terms
    end

    def self.match_code(terms)
      /\A#{Setting["reporting_code_prefix",User.pon_id]}-\d\d\d\d-\d\d-(\d*)\z/.match(terms)
    end

    def self.for_summary
      summary = {}
      categories = ActsAsTaggableOn::Tag.category_names.sort
      geozones   = Geozone.names.sort

      groups = categories + geozones
      groups.each do |group|
        summary[group] = search(group).last_week.sort_by_confidence_score.limit(3)
      end
      summary
    end

   def geo_hot_score()
      count_comments_reporting = self.comments.joins(:user).where("users.public_map = ?", TRUE).group(:user_id).count

      count_comments_reporting.each do |elem|
        count_comments_reporting[elem[0]] = elem[1]* Rails.application.config.new_comment
      end
     #commento mio
     # count_votes_reporting = self.votes.where(voter_type: "User").group(:voter_id).count
     # count_votes_comments = self.comments.includes(:vote).where(:votes => {voter_type: "User"}).group(:voter_id).count
      totale = count_comments_reporting #.merge(count_votes_reporting)
     # totale = totale.merge(count_votes_comments)

     # codes_and_totals = [count_comments_reporting , count_votes_reporting,count_votes_comments]

      codes_and_totals = [count_comments_reporting ] #miaa


      totals = codes_and_totals.reduce({}) do |sums, location|
        sums.merge(location) { |_, a, b| a + b }
      end

      heat_markers = Array.new
      heat_val = Array.new
      i=0
      totals.each do |item|
        #coords = User.includes(:geolocation).where(id: item[0]).pluck(:lat, :lon)#commento
        coords = MapLocation.where(localizable_type: "User").where(localizable_id: item[0]).pluck(:latitude, :longitude)
        if coords.length > 0
          #massimo peso di un item: 50
          #item[1] = item[1] > 50 ? 50 : item[1]

          coord = [coords[0][0],coords[0][1],item[1]]
          heat_val[i] = item[1]
          heat_markers[i] = Array.new(coord)
          i+=1
        end
      end

      if i >= Setting['min_interaction_for_heatmap',User.pon_id].to_i
        heat_markers.each do |item|
          if heat_val.max == heat_val.min
            val_norm = 100
          else
            val_norm = ((item[2]-heat_val.min)*100/(heat_val.max-heat_val.min))
          end
          item[2]=val_norm
          #logger.debug val_norm
        end
        #logger.debug "\n\nstats norm--------------------------------\n"
        #logger.debug heat_markers
      else
        heat_markers = Array.new
      end

      heat_markers

    end

    #commento_mio
    def total_votes
      cached_votes_up
    end


=begin
    def voters
      User.active.where(id: votes_for.voters)
    end
=end


    def editable?(user)
      total_votes <= Setting["max_votes_for_reporting_edit",user.pon_id].to_i
    end

    def editable_by?(user)
      editable?(user) && (author_id == user.id || (user.pon_id==self.pon_id && user.can_moderate?))
    end

    def moderable_comments_by?(user)
      user && user.pon_id==self.pon_id && user.can_moderate?
    end

    def votable_by?(user)
      user && user.level_two_or_three_verified?
    end

    def retired?
      retired_at.present?
    end

    #commento_mio
=begin    def register_vote(user, vote_value)
      if votable_by?(user) && !archived?
        vote_by(voter: user, vote: vote_value)
      end
    end
=end

    def code
      "#{Setting['reporting_code_prefix',User.pon_id]}-#{created_at.strftime('%Y-%m')}-#{id}"
    end

    def after_commented
      save # updates the hot_score because there is a before_save
    end

  #commento mio
  def calculate_hot_score
      self.hot_score = ScoreCalculator.hot_score(created_at,
                                                 0,#total_votes,
                                                 0,#total_votes,
                                                 comments_count)
    end

    def calculate_confidence_score
      #self.confidence_score = ScoreCalculator.confidence_score(total_votes, total_votes)
    end

    def after_hide
      tags.each{ |t| t.decrement_custom_counter_for('Reporting') }
    end

    def after_restore
      tags.each{ |t| t.increment_custom_counter_for('Reporting') }
      send_reporting_to_barisolve

    end


    def self.votes_needed_for_success
      Setting['votes_for_reporting_success',User.pon_id].to_i
    end

    def send_reporting_to_barisolve
      begin
        uri = URI.parse("#{Rails.application.config.reportings_login}/cdb-restful-ws/bareport/login")
        request = Net::HTTP::Post.new(uri)
        request.basic_auth(Rails.application.config.rep_user, Rails.application.config.rep_password)
        request.content_type = "application/json"
        request["Accept"] = "application/json"

        req_options = {
          use_ssl: uri.scheme == "https",
        }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        #funzione per prendere nome e cognome
        full_name = @current_user.name
        half_name = full_name.split(' ')
        name = half_name.first
        surname = half_name.last

        #email utente
        email = @current_user.email

        p_token = JSON.parse(response.body)['token']
        p_titolo = self.title
        p_descrizione = self.description
        p_indirizzo = self.address == '' ? " " : self.address

        #sezione dati cablati
        p_fonte = "baripartecipa"
        p_username = email #"test1@baripartecipa.it" - utente loggato
        p_nome = name
        p_cognome = surname
        p_riferimenti = email #"test1@baripartecipa.it" - utente loggato
        p_email = email  #"test1@baripartecipa.it" - utente loggato

        p_tiposegnalazione = ReportingType.find(self.reporting_type_id).category_id.to_s


        json_payload = {multipart: true, p_token: p_token, p_titolo: p_titolo, p_descrizione: p_descrizione, p_tiposegnalazione: p_tiposegnalazione, p_indirizzo: p_indirizzo,
          p_fonte: p_fonte, p_username: p_username, p_nome: p_nome, p_cognome: p_cognome, p_riferimenti: p_riferimenti, p_email: p_email}
          #p_posizione: p_posizione, p_latitudine_campo: p_latitudine_campo, p_longitudine_campo: p_longitudine_campo,
          #p_picture:  File.new(p_picture.first[1]['cached_attachment'], 'rb')

        if self.map_location.present?
          p_posizione = self.map_location.latitude.to_s + "|" + self.map_location.longitude.to_s
          p_latitudine_campo = self.map_location.latitude.to_s
          p_longitudine_campo = self.map_location.longitude.to_s

          json_payload[:p_posizione] = p_posizione
          json_payload[:p_latitudine_campo] = p_latitudine_campo
          json_payload[:p_longitudine_campo] = p_longitudine_campo

        end

        if self.images.present?
          p_picture =  File.new(Rails.root.to_s+"/public"+self.images.first.attachment.url, 'rb')
          json_payload[:p_picture] = p_picture
        end

        logger.debug "************ setPrivacy checkbox-values *************"
        logger.debug "******* payload:"
        logger.debug json_payload
        logger.debug "**************************************"

        logger.info "************ setPrivacy checkbox-values *************"
        logger.info "******* payload:"
        logger.info json_payload
        logger.info "**************************************"

           response1 = RestClient.post(
             "https://esb.comune.bari.it/cdb-restful-ws/bareport/send",
             json_payload,
             headers={content_type: "multipart/form-data", accept: :json}
           )

           logger.debug "************ setPrivacy setNewReporting *************"
           logger.debug response1.to_s
           logger.debug "*************************************"

           logger.info "************ setPrivacy setNewReporting *************"
           logger.info response1.to_s
           logger.info "*************************************"


             true

           rescue RestClient::ExceptionWithResponse => e
              logger.error "----------In Socket errror---------------------"
              logger.error e.to_s
              logger.error request.raw_post
              return false
             #redirect_to :back, :flash => { :alert =>t('reportings.index.featured_reportings_error')}
            rescue => e
              logger.error "----------Eerroreeee4----------------------------------"
              logger.error e.to_s
              #redirect_to :back, :flash => { :alert =>t('reportings.index.featured_reportings_error')}
              #raise
              return false
            rescue RestClient::Exception => e
              logger.error e.http_body
              logger.error e.to_s
              #redirect_to :back, :flash => { :alert =>t('reportings.index.featured_reportings_error')}
              return false
          end

    end

=begin
    def successful?
      total_votes >= Reporting.votes_needed_for_success
    end
=end

    def archived?
      created_at <= Setting["months_to_archive_reportings",User.pon_id].to_i.months.ago
    end

    def notifications
      reporting_notifications
    end

    def users_to_notify
      (followers).uniq
      #rimosso voters perchè la funzione non prevede votanti
      #(voters + followers).uniq
    end

    def self.reportings_orders(user)
      orders = %w{all forward at_work closed resolved}
      orders
    end




    protected

      def set_responsible_name
        if author && author.document_number?
          self.responsible_name = author.document_number
        end
      end


      def images_from_local
        errors.add(:images, :blank) if !images.first.present? && !external_id
      end

      def map_location_from_local
        errors.add(:map_location, :blank) if !map_location && !external_id
      end

    end
