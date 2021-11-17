class Polls::ExtPollsApiController < ApplicationController
  skip_authorization_check
  skip_before_action :verify_authenticity_token

  include ExtPollsApiHelper
  include CfValidationHelper

  # Libreria necessaria per produrre risposte di tipo jsonrpc
  require "json-rpc-objects/v20/request"
  require "json-rpc-objects/v20/response"

  def initialize
    super
    @api_logger = ActiveSupport::TaggedLogging.new(Logger.new(File.join(Rails.root, 'log', 'jsonrpc_endpoint.log')))
  end

  def jsonrpcendpoint
    # Tutte le richieste JSON RPC arriveranno qui.

    # Effettuiamo il parsing della request:
    parsed_request_body = JsonRpcObjects::V20::Request::parse(request.body.read)

    request_time = Time.now.utc.to_datetime.rfc3339
    request_uri = request.url
    request_method = request.request_method
    requested_action = parsed_request_body.method

    # Chiamiamo il metodo facendo leva sulla valutazione Ruby
    # Verrà chiamato il metodo con nome "parsed_request_body.method" con i parametri
    # Notare che se i parametri sono un hash, verrà popolata la variabile di istanza @keyword_params
    params ||= parsed_request_body.instance_variable_get(:@keyword_params) || parsed_request_body.instance_variable_get(:@params)

    # Usando il metodo "method.call", possiamo chiamare il metodo specificato come argomento della funzione "method"
    # passando come parametri l'hash di parametri ricavato precedentemente.
    begin
      jsonrpc_response = generate_jsonrpc_response(method(parsed_request_body.method).call(params))
    rescue ArgumentError => e
      jsonrpc_response = generate_jsonrpc_response(get_error_hash('MISSING_ARGS', e.message))

      @api_logger.tagged(request_time) do
        @api_logger.info "Requested action `#{requested_action}` with method `#{request_method}` at uri `#{request_uri}`; HTTP response code #{Rack::Utils::SYMBOL_TO_STATUS_CODE[get_error_http_status(e.message)]}"
      end

      render json: jsonrpc_response, :status => get_error_http_status('MISSING_ARGS') and return
    rescue JwtError => e
      jsonrpc_response = generate_jsonrpc_response(get_error_hash(e.message))

      @api_logger.tagged(request_time) do
        @api_logger.info "Requested action `#{requested_action}` with method `#{request_method}` at uri `#{request_uri}`; HTTP response code #{Rack::Utils::SYMBOL_TO_STATUS_CODE[get_error_http_status(e.message)]}"
      end

      render json: jsonrpc_response, :status => get_error_http_status(e.message) and return
    rescue GenericError => e
      # I GenericError possono avere in più il parametro "additional_message"
      jsonrpc_response = generate_jsonrpc_response(get_error_hash(e.message, e.additional_message))

      @api_logger.tagged(request_time) do
        @api_logger.info "Requested action `#{requested_action}` with method `#{request_method}` at uri `#{request_uri}`; HTTP response code #{Rack::Utils::SYMBOL_TO_STATUS_CODE[get_error_http_status(e.message)]}"
      end

      render json: jsonrpc_response, :status => get_error_http_status(e.message) and return
    end

    # Renderizzazione risposta nei casi in cui non ci sia errore
    @api_logger.tagged(request_time) do
      @api_logger.info "Requested action `#{requested_action}` with method `#{request_method}` at uri `#{request_uri}`; HTTP response code 200"
    end
    render json: jsonrpc_response

  end

  def status
    # Endpoint come da linee guida:
    # https://www.agid.gov.it/sites/default/files/repository_files/04_raccomandazioni_di_implementazione.pdf

    # In questo caso il server che fornisce le API è il medesimo che espone il servizio status,
    # quindi risponderemo sempre con 200.

    respond_to do |format|
      format.any {
        response.headers['Content-Type'] = 'application/problem+json; charset=utf-8'
        render json: {
            title: "Il servizio funziona correttamente.",
            status: 200
        }
      }
    end
  end

  private

  def get_session_key(username:, password:)
    check_blank_args({:username => username, :password => password})

    require 'jwt'

    user = User.find_by_email(username)

    # Verifichiamo se l'utenza esiste
    if user.nil?
      raise GenericError, 'INVALID_CREDENTIALS'
    end

    # Verifichiamo se username e password son corrette:
    unless user.valid_password?(password)
      raise GenericError, 'INVALID_CREDENTIALS'
    end

    # Restituisco il JWT codificato
    generate_jwt user.pon_id

  end

  def list_surveys(sSessionKey:, iPonId:, q: '', iSurveyId: '', state: '', startDate: '', endDate: '')
    check_blank_args({:sSessionKey => sSessionKey, :iPonId => iPonId})
    authorize_jwt(sSessionKey)

    # Filtro
    found_surveys = query_surveys(iPonId, q, iSurveyId, state, startDate, endDate)

    result_polls = []

    # Trasformo
    found_surveys.each do |survey|
      result_polls.push({
                            "id": survey.id,
                            "name": survey.name,
                            "startsAt": survey.starts_at,
                            "endsAt": survey.ends_at,
                            "published": survey.published,
                            "summary": survey.summary,
                            "description": survey.description,
                            "iPonId": survey.pon_id,
                        })
    end

    result_polls

  end

  def query_surveys(iPonId, q, iSurveyId, state, startDate, endDate)
    # Costruzione filtri:

    # Base: tutti i Poll pubblicati destinati all'uso esterno del pon ID fornito
    query_polls = Poll
                      .ext_use
                      .published
                      .where(:pon_id => iPonId)
                      .select('id', 'name', 'starts_at', 'ends_at', 'published', 'summary', 'description', 'pon_id')

    # Aggiungiamo le restanti casistiche

    unless validate_survey_state(state)
      raise GenericError, 'WRONG_SURVEY_STATE'
    end

    # Se viene fornito un id, restituiamo quel poll
    if iSurveyId != ''
      begin
        result_polls = query_polls.find(iSurveyId)       
      rescue ActiveRecord::RecordNotFound
        raise GenericError, 'SURVEY_NOT_FOUND'
      end
      result_polls = query_polls.where(id: iSurveyId)
      return result_polls
    end

    # Altri filtri
    query_polls = query_polls.where("starts_at >= ?", startDate) if startDate.present?
    query_polls = query_polls.where("ends_at <= ?", endDate) if endDate.present?
    query_polls = query_polls.where("LOWER(name) LIKE LOWER(?)", "%#{q}%") if q.present?
    query_polls = eval("query_polls.#{state}") if state.present?

    query_polls
  end

  def add_participants(sSessionKey:, iSurveyId:, aParticipantData:)
    check_blank_args({:sSessionKey => sSessionKey,
                      :iSurveyId => iSurveyId,
                      :aParticipantData => aParticipantData})
    authorize_jwt(sSessionKey)
    poll = check_survey_validity(iSurveyId)

    added_participants_data = []

    aParticipantData.each do |participant|

      # Verifichiamo che esistano tutti i campi richiesti:
      unless participant["email"].present? and participant["lastname"].present? and participant["name"].present? and participant["fiscalCode"].present?
        raise GenericError.new('MISSING_USER_DATA', participant.to_json)
      end

      # Verifichiamo codice fiscale
      raise GenericError.new('MALFORMED_USER_DATA', "Invalid fiscal code `#{participant["fiscalCode"]}` for user `#{participant['name']} #{participant['lastname']}`") unless fiscal_code_validation(participant["fiscalCode"])

      # Verifichiamo correttezza e-mail
      raise GenericError.new('MALFORMED_USER_DATA', "Invalid e-mail address `#{participant["email"]}` for user `#{participant['name']} #{participant['lastname']}`") unless email_valid?(participant["email"])

      if user_already_present? participant
        # L'utente esiste già: dobbiamo aggiornare i suoi dati
        begin
          user = update_user_data(participant)
        rescue ActiveRecord::RecordInvalid => e
          raise GenericError.new('MALFORMED_USER_DATA', e.message)
        end

        # Valorizzo il voter, che mi servirà per comporre il dato di restituzione
        # N.B. L'utente era già stato aggiunto, per cui NON rigenero il token.
        voter = Poll::Voter.find_by user_id: user.id

      else
        # L'utente non esiste nel DB, possiamo procedere
        # 1 - Aggiungere nel db tabella users
        begin
          user = User.create!(
              pon_id: poll["pon_id"],
              username: "#{participant["lastname"]} #{participant["name"]}",
              password: "12345678",
              password_confirmation: "12345678",
              email: participant["email"],
              terms_of_service: "1",
              cod_fiscale: participant["fiscalCode"],
              privacy: true,
              skip_map: "1",
              confirmed_at: Time.current,
          )
        rescue ActiveRecord::RecordInvalid => e
          raise GenericError.new('MALFORMED_USER_DATA', e.message)
        end

        # Si può procedere all'inserimento dell'utente nella tabella poll_voters
        voter = Poll::Voter.create!(
            user: user,
            poll: poll,
            origin: 'ext',
            token: SecureRandom.hex(32)
        )

      end


      # 3 - Aggiorniamo l'array di restituzione:
      added_participants_data.push({
                                       :email => participant["email"],
                                       :lastname => participant["lastname"],
                                       :name => participant["name"],
                                       :fiscalCode => participant["fiscalCode"],
                                       :sTokenId => voter["token"]
                                   })

    end

    added_participants_data

  end

  def invite_participants(sSessionKey:, iSurveyId:, aTokenIds:, bEmail: true)
    check_blank_args({:sSessionKey => sSessionKey,
                      :iSurveyId => iSurveyId,
                      :aTokenIds => aTokenIds})
    authorize_jwt(sSessionKey)
    poll = check_survey_validity(iSurveyId)

    # Controllo formale su tutti i token inviati
    aTokenIds.each do |invite_token|
      poll_voter = Poll::Voter.find_by token: invite_token

      if poll_voter.nil?
        raise GenericError.new('INVALID_INVITATION_TOKEN', invite_token)
      end
    end

    invited_participants_data = []

    aTokenIds.each do |invite_token|
      poll_voter = Poll::Voter.find_by token: invite_token

      begin
        user = User.find(poll_voter["user_id"])
      rescue ActiveRecord::RecordNotFound
        # Utente non trovato
        invited_participants_data.push({
                                           "sTokenId": invite_token,
                                           "bSuccess": false
                                       })
        raise GenericError.new('USER_NOT_FOUND', poll_voter["user_id"])
      end

      if poll_voter["invitation_sent"] == true and bEmail
        # Se bEmail è true, significa che non dobbiamo ri-spedire gli inviti a chi l'ha già ricevuto
        invited_participants_data.push({
                                           "sTokenId": invite_token,
                                           "bSuccess": false
                                       })
        next
      end

      begin
        Mailer.ext_poll_vote_invite(invite_token, user, poll).deliver_later
      rescue Net::SMTPError, SocketError => e
        # Se l'invio fallisce, logghiamo e impostiamo a "false" il flag di successo
        Rails.logger.error "Error while trying to send poll invitation email: #{e.message}"
        invited_participants_data.push({
                                           "sTokenId": invite_token,
                                           "bSuccess": false
                                       })
        next
      end

      poll_voter.update!(invitation_sent: true)

      invited_participants_data.push({
                                         "sTokenId": invite_token,
                                         "bSuccess": true
                                     })

    end

    invited_participants_data

  end

  def delete_participants(sSessionKey:, aParticipantData:)
    # Metodo di utility non previsto dalle specifiche ma utile per test/debug

    check_blank_args({:sSessionKey => sSessionKey,
                      :aParticipantData => aParticipantData
                     })
    authorize_jwt(sSessionKey)

    deleted_participant = []

    aParticipantData.each do |participant|
      # Verifichiamo che esistano i campi necessari:
      unless participant["email"].present?
        raise GenericError.new('MISSING_USER_DATA', participant.to_s)
      end

      user = User.with_deleted.find_by email: participant["email"]

      if user.nil?
        deleted_participant.push({
                                     "email": participant["email"],
                                     "bSuccess": false
                                 })
        next
      end

      poll_voter = Poll::Voter.find_by user_id: user.id

      Poll::Answer.delete_all(author_id: user.id)

      poll_voter.destroy
      user.really_destroy!

      deleted_participant.push({
                                   "email": participant["email"],
                                   "bSuccess": true
                               })

    end

    deleted_participant
  end

  def add_test_votes(sSessionKey:, iSurveyId:, aToken:)
    # Metodo di utility non previsto dalle specifiche ma utile per test/debug

    check_blank_args({:sSessionKey => sSessionKey,
                      :iSurveyId => iSurveyId,
                      :aToken => aToken
                     })
    authorize_jwt(sSessionKey)
    check_survey_validity(iSurveyId)

    poll_voters = Poll::Voter.where(token: aToken)

    questions = Poll::Question.where(poll_id: iSurveyId)

    questions.each do |question|
      answers = Poll::Question::Answer.where(question_id: question.id)

      # Per ogni domanda, per ogni utente di test, scelgo casualmente una delle possibili
      # risposte.

      poll_voters.each do |voter|
        Poll::Answer.create!(author_id: voter.user_id,
                             question_id: question.id,
                             answer: answers.sample(1).first.title,
                             submitted: true,
                             token: voter.token
        )
      end

    end

  end

  def survey_stats(sSessionKey:, iSurveyId:)
    check_blank_args({:sSessionKey => sSessionKey,
                      :iSurveyId => iSurveyId
                     })
    authorize_jwt(sSessionKey)
    poll = check_survey_validity(iSurveyId)

    # Cerco i votanti
    voters = Poll::Voter.all.where(poll_id: iSurveyId)

    # Ricavo gli id delle domande del poll
    poll_questions_ids = Poll::Question.where(poll_id: poll.id).ids

    # Ciclo i votanti e costruisco gli oggetti da restituire
    users_list = []
    voters.each do |voter|

      user = User.find(voter.user_id)

      # Ricavo le risposte fornite
      answer_list = get_answers_object(poll_questions_ids, voter)

      stats_object = {
          email: user.email,
          username: user.username,
          fiscalCode: user.cod_fiscale,
          sTokenId: voter.token,
          bOpened: voter.opened,
          bCompleted: voter.confirmed,
          aAnswersList: answer_list
      }

      users_list.push(stats_object)
    end

    {
        aUsersList: users_list
    }
  end

  def survey_users_stats(sSessionKey:, aFiscalCodes:)
    check_blank_args({:sSessionKey => sSessionKey,
                      :aFiscalCodes => aFiscalCodes
                     })
    authorize_jwt(sSessionKey)

    stats_obj = []

    aFiscalCodes.each do |fiscal_code|
      surveys_array = []

      # Ricavo l'id utente dal codice fiscale
      user = User.find_by(cod_fiscale: fiscal_code)

      if user.nil?
        raise GenericError.new('INVALID_FISCAL_CODE', fiscal_code)
      end

      user_id = user.id

      # Ricavo le votazioni relative all'utente (solo utenti invitati, quindi da esterno)
      poll_voters = Poll::Voter.all.where(user_id: user_id).where(invitation_sent: true)

      # Costruisco le statistiche per ogni sondaggio
      poll_voters.each do |voter|
        surveys_array.push({
                               iSurveyId: voter.poll_id,
                               bOpened: voter.opened,
                               bCompleted: voter.confirmed
                           })
      end

      # Aggiungo il record all'array da restituire
      stats_obj.push({
                         sFiscalCode: fiscal_code,
                         aSurveys: surveys_array
                     })
    end

    {
        aUsersSurveysList: stats_obj
    }

  end

end
