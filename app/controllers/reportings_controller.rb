require 'rest-client'

class ReportingsController < ApplicationController
  include ServiceFlags
  include CommentableActions
  include FlagActions
  include ReportingsHelper

  before_action :parse_tag_filter, only: :index
  before_action :load_categories, only: [:index, :new, :create, :edit, :map, :summary]
  before_action :load_geozones, only: [:edit, :map, :summary]
  before_action :authenticate_user!, except: [:index, :show, :map, :summary, :json_data, :large_map]
  before_action :destroy_map_location_association, only: :update
  before_action :set_view, only: :index
  before_action :load_data, only: [:edit, :update, :show]     #moderazione su reporting

  skip_authorization_check only: :json_data

  service_flag :reportings

  invisible_captcha only: [:create, :update], honeypot: :subtitle

  has_orders ->(c) { Reporting.reportings_orders(c.current_user) }, only: :index
  has_orders %w{most_voted newest oldest}, only: :show

  load_and_authorize_resource except: [:json_data]
  helper_method :resource_model, :resource_name
  respond_to :html, :js

  #add segnalazioni breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.reportings"), :reportings_path

  def num_reportings_from_esb
    20
  end

  def show
    if read_only_service
      render action: "show_esb"
    end
    super
    load_data
    @notifications = @reporting.notifications
    @related_contents = Kaminari.paginate_array(@reporting.relationed_contents).page(params[:page]).per(5)

    redirect_to reporting_path(@reporting), status: :moved_permanently if request.path != reporting_path(@reporting)
  end


  def large_map
    @reportings=@reportings.by_user_pon
  end

  def new
    if read_only_service
      @reporting_types_select_options = get_reporting_types_from_url.collect { |t| [ t.nome, t.id ] }
    else
      @reporting_types_select_options = ReportingType.all.where("category_id > 0").order(nome: :asc).collect { |t| [ t.nome, t.id ] }
    end
  end

  def social_flag
    @reporting = Reporting.find_by(id: params[:id])
    @reporting.social_content.social_access = !@reporting.social_content.social_access
    @reporting.social_content.save
    @reporting.touch
    redirect_to :back, notice: t('notice.operaction_successfull')
  end


  def create
    @reporting = Reporting.new(reporting_params.merge(author: current_user,pon_id: User.pon_id, skip_map: '1'))
    if @reporting.save
        if current_user.administrator? || current_user.moderator?
          @reporting.send_reporting_to_barisolve
          redirect_to share_reporting_path(@reporting), notice: I18n.t('flash.actions.create.reporting')
        else
          redirect_to user_path(current_user), notice: I18n.t('flash.actions.create.reporting_in_approval')      #moderazione su reporting
        end

        if current_user.administrator?
          if params[:reporting][:social_content][:social_access].to_i > 0
            SocialContent.create(sociable: @reporting, social_access: true)
          else
            SocialContent.create(sociable: @reporting, social_access: false)
          end
        else

          social_service = Setting.find_by(key: 'service_social.reportings',pon_id: User.pon_id).value
          SocialContent.create(sociable: @reporting, social_access: social_service)
        end

    else
      render :new
    end

  end

  def  moderation_flag
    reporting = Reporting.find_by(id: params[:id])
    reporting.moderation_flag = !reporting.moderation_flag
    reporting.save
    redirect_to :back, notice: t('notice.operaction_successfull')
  end


#  def index_customization
#    discard_archived
#    load_retired
#    load_successful_reportings
#    load_featured unless @reporting_successful_exists
#  end

  def index
    if read_only_service
      if !params[:page]
        params[:page] = 0
      end
      #@reporting_types = get_reporting_types_from_url
      array = get_reportings_from_url(params[:page])
      if !array
        render action: "show_esb_error"
      else
        @reportings = Kaminari.paginate_array(array,total_count: @totalElements).page(params[:page]).per(num_reportings_from_esb)
        @tag_cloud = tag_cloud
        @banners = Banner.by_user_pon.with_active
      end
    else
      super
    end
  end

#commento mio
=begin
  def vote
    @reporting.register_vote(current_user, 'yes')
    set_reporting_votes(@reporting)
  end
=end

  def retire
    if valid_retired_params? && @reporting.update(retired_params.merge(retired_at: Time.current))
      redirect_to reporting_path(@reporting), notice: t('reportings.notice.retired')
    else
      render action: :retire_form
    end
  end

  def retire_form
  end

  def share
    if Setting['reporting_improvement_path',User.pon_id].present?
      @reporting_improvement_path = Setting['reporting_improvement_path',User.pon_id]
    end
  end

#commentata io
=begin
  def vote_featured
    @reporting.register_vote(current_user, 'yes')
    set_featured_reporting_votes(@reporting)
  end
=end

  def summary
    @reportings = Reporting.for_summary
    @tag_cloud = tag_cloud
  end

  def json_data
    load_data
    if read_only_service
      data = {
        reporting_id: @reporting.id,
        title: @reporting.title,
        author_id: nil,
        url: reporting_path(@reporting)
      }.to_json
    else
      reporting =  Reporting.find(params[:id])
      data = {
        reporting_id: reporting.id,
        title: reporting.title,
        author_id: reporting.author_id,
        url: reporting_path(reporting)
      }.to_json

    end

    respond_to do |format|
      format.json { render json: data }
    end
  end

  private

  #autenticazione user su barisolve
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
      p_titolo = params[:reporting][:title] #"Test Almaviva (si prega di non considerare il presente messaggio)"
      p_descrizione = "#{@reporting.id}" + " - " + params[:reporting][:description] #"Test Almaviva (si prega di non considerare il presente messaggio)"
      p_indirizzo = params[:reporting][:address] == '' ? " " : params[:reporting][:address]

      #sezione dati cablati
      p_fonte = "baripartecipa"
      p_username = email #"test1@baripartecipa.it" - utente loggato
      p_nome = name
      p_cognome = surname
      p_riferimenti = email #"test1@baripartecipa.it" - utente loggato
      p_email = email  #"test1@baripartecipa.it" - utente loggato

      p_tiposegnalazione = ReportingType.find(params[:reporting][:reporting_type_id]).category_id.to_s


      json_payload = {multipart: true, p_token: p_token, p_titolo: p_titolo, p_descrizione: p_descrizione, p_tiposegnalazione: p_tiposegnalazione, p_indirizzo: p_indirizzo,
        p_fonte: p_fonte, p_username: p_username, p_nome: p_nome, p_cognome: p_cognome, p_riferimenti: p_riferimenti, p_email: p_email}
        #p_posizione: p_posizione, p_latitudine_campo: p_latitudine_campo, p_longitudine_campo: p_longitudine_campo,
        #p_picture:  File.new(p_picture.first[1]['cached_attachment'], 'rb')

      if params[:reporting][:skip_map] != "1"
        p_posizione = params[:reporting][:map_location_attributes][:latitude] + "|" + params[:reporting][:map_location_attributes][:longitude]
        p_latitudine_campo = params[:reporting][:map_location_attributes][:latitude]
        p_longitudine_campo = params[:reporting][:map_location_attributes][:longitude]

        json_payload[:p_posizione] = p_posizione
        json_payload[:p_latitudine_campo] = p_latitudine_campo
        json_payload[:p_longitudine_campo] = p_longitudine_campo

      end

      if params[:reporting][:images_attributes].present?
        p_picture =  File.new(params[:reporting][:images_attributes].first[1]['cached_attachment'], 'rb')
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

        # response1 = RestClient.post(
        #   "https://esb.comune.bari.it/cdb-restful-ws/bareport/send",
        #   json_payload,
        #   headers={content_type: "multipart/form-data", accept: :json}
        # )

        # logger.debug "************ setPrivacy setNewReporting *************"
        # logger.debug response1.to_s
        # logger.debug "*************************************"

        # logger.info "************ setPrivacy setNewReporting *************"
        # logger.info response1.to_s
        # logger.info "*************************************"


        #   true

        # rescue RestClient::ExceptionWithResponse => e
        #    logger.error "----------In Socket errror---------------------"
        #    logger.error e.to_s
        #    logger.error request.raw_post
        #    return false
        #   #redirect_to :back, :flash => { :alert =>t('reportings.index.featured_reportings_error')}
        #  rescue => e
        #    logger.error "----------Eerroreeee4----------------------------------"
        #    logger.error e.to_s
        #    #redirect_to :back, :flash => { :alert =>t('reportings.index.featured_reportings_error')}
        #    #raise
        #    return false
        #  rescue RestClient::Exception => e
        #    logger.error e.http_body
        #    logger.error e.to_s
        #    #redirect_to :back, :flash => { :alert =>t('reportings.index.featured_reportings_error')}
        #    return false
        end



  end

    # get lista reporting types
    def get_reporting_types_from_url
      array = Array.new
      begin
        response = RestClient.post 'https://esb.comune.bari.it/cdb-restful-ws-v2/bareport/categories' , {}, {content_type: :json, accept: :json}
        json_response = JSON.parse(response)
        json_response.each do |cat|
          cat["listaCategorie"].each do |item|
            array.push(
              ReportingType.new(
                id: item["idCategoria"],
                nome: item["nome"]
              )
            )
          end
        end
      rescue SocketError => e
        render action: "show_esb_error"
      rescue => e
        logger.error "----------In Socket errror"
        logger.error e.to_s
        #raise
      rescue RestClient::Exception => e
        logger.error e.http_body
        logger.error e.to_s
      end
      array
    end

    def get_reportings_from_url(p_page)
      array = Array.new
      p_page = p_page.to_i

      if p_page > 1
        p_page = p_page - 1
      end
      begin
        response = RestClient.post 'https://esb.comune.bari.it/cdb-restful-ws-v2/bareport/segnalazioni' , {p_page: p_page, p_size: num_reportings_from_esb}, {content_type: :json, accept: :json}

        json_response = JSON.parse(response)
        @totalElements = json_response["totalElements"].to_i

        json_response["segnalazioni"].each do |item|
          user = User.first()
          rep_type = ReportingType.new()
          map_loc = MapLocation.new()
          user.username = item["username"]
          rep_type.imageMarker = item["imageMarker"]
          rep_type.nome = item["tipoDescrizione"]
          url_preview = item["foto"].strip
          if url_preview.end_with?(".it")
            url_preview = nil
          end
          map_loc =  MapLocation.new
          #map_loc.reporting_id = item["idSegnalazione"]
          map_loc.localizable_id = item["idSegnalazione"]
          map_loc.localizable_type = "Reporting"
          map_loc.latitude = item["latitudeX"]
          map_loc.longitude = item["longitudeY"]
          rep = Reporting.new(
            id: item["idSegnalazione"],
            address: item["indirizzo"],
            title: item["titolo"],
            created_at: item["data"],
            author: user,
            reporting_type: rep_type,
            description_status: item["statoDescrizione"],
            note: item["nota"],
            description: item["descrizione"],
            url_image_preview: url_preview,
            map_location: map_loc)

          array.push(rep)

        end
        session[:p_page]=p_page
        array
      rescue SocketError => e
        render action: "show_esb_error"
      rescue => e
        logger.error "----------In Socket errror"
        #raise
      rescue RestClient::Exception => e
        logger.error e.http_body
      end
    end

    def reporting_params
      if current_user.administrator? || current_user.moderator?
        moderation_entity_v=1
      else
        moderation_entity_v=2
      end
      params.require(:reporting).permit(:title, :question, :summary, :description, :external_url, :video_url,
                                      :address, :created_at, :status_start_date,   #mia
                                      :lat, :lon, :note,   #mia
                                      :responsible_name, :tag_list, :terms_of_service, :geozone_id, #:skip_map,
                                      :reporting_type_id,  #mia sono i parametri presi da input
                                      :description_status,
                                      :work_status,
                                      :social_access, #Identificazione Social
                                      social_content_attributes: [:social_access], #Identificazione Social
                                      images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                      documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                      map_location_attributes: [:latitude, :longitude, :zoom])#.merge(pon_id: User.pon_id)
                                      .merge(moderation_entity: moderation_entity_v)

    end

    def retired_params
      params.require(:reporting).permit(:retired_reason, :retired_explanation)
    end

    def valid_retired_params?
      @reporting.errors.add(:retired_reason, I18n.t('errors.messages.blank')) if params[:reporting][:retired_reason].blank?
      @reporting.errors.add(:retired_explanation, I18n.t('errors.messages.blank')) if params[:reporting][:retired_explanation].blank?
      @reporting.errors.empty?
    end

    def resource_model
      Reporting
    end
#commentata io
=begin
    def set_featured_reporting_votes(reportings)
      @featured_reportings_votes = current_user ? current_user.reporting_votes(reportings) : {}
    end
=end
    def discard_archived
      @resources = @resources.not_archived unless @current_order == "archival_date"
    end

    def load_retired
      if params[:retired].present?
        @resources = @resources.retired
        @resources = @resources.where(retired_reason: params[:retired]) if Reporting::RETIRE_OPTIONS.include?(params[:retired])
      else
        @resources = @resources.not_retired
      end
    end

    def load_featured
      return unless !@advanced_search_terms && @search_terms.blank? && @tag_filter.blank? && params[:retired].blank? && @current_order != "recommendations"
      @featured_reportings = Reporting.where(moderation_entity: 1).not_archived.sort_by_confidence_score.limit(3)
      if @featured_reportings.present?
        #commentata io
        #set_featured_reporting_votes(@featured_reportings)
        @resources = @resources.where('reportings.id NOT IN (?)', @featured_reportings.map(&:id))
      end
    end

    #moderazione su reporting
    def load_data
      if read_only_service

        p_page = session[:p_page].to_i
        reportings = get_reportings_from_url(p_page)
        @id = params[:id].to_i
        @reporting = reportings.select {|e| e.id == @id}.first
      else
        @reporting = Reporting.find(params[:id])
        if !@reporting.load_entity?(current_user)
          raise CanCan::AccessDenied
        end
      end
    end

    def set_view
      @view = (params[:view] == "minimal") ? "minimal" : "default"
    end

    def load_successful_reportings
        @reporting_successful_exists = Reporting.successful.exists?
      end

    def destroy_map_location_association
      map_location = params[:reporting][:map_location_attributes]
      skip_map =params[:reporting][:skip_map]
      if skip_map == "1" || (map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?)
        MapLocation.destroy(map_location[:id])
      end
    end

end
