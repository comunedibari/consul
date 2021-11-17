module ExtPollsApiHelper
  class JwtError < StandardError; end

  class GenericError < StandardError
    attr_reader :additional_message

    def initialize(msg = "", additional_message = "")
      @additional_message = additional_message
      super(msg)
    end
  end

  def get_error_hash(error_code, error_msg = '')
    # Gestione errore: a seconda della stringa di errore in arrivo
    # produciamo l'hash errore corretto pronto per essere renderizzato jsonrpc
    case error_code
    when 'INVALID_CREDENTIALS'
      {:code => 0, :message => "Invalid Credentials"}
    when 'MISSING_ARGS'
      {:code => 10, :message => "Required Arguments #{error_msg}"}
    when 'USER_NOT_FOUND'
      {:code => -2, :message => "User not found with ID #{error_msg}"}
    when 'EXPIRED_TOKEN'
      {:code => -1, :message => "Expired Token"}
    when 'INVALID_TOKEN'
      {:code => -3, :message => "Invalid Token"}
    when 'INVALID_TOKEN_DATA'
      {:code => -3, :message => "Invalid Token Data"}
    when 'SURVEY_NOT_FOUND'
      {:code => -4, :message => "Survey Not Found"}
    when 'INVALID_SURVEY'
      {:code => -7, :message => "Invalid Survey Id"}
    when 'MALFORMED_USER_DATA'
      {:code => -5, :message => "Malformed User Data: #{error_msg}"}
    when 'MISSING_USER_DATA'
      {:code => -6, :message => "Mandatory Fields Missing For User: #{error_msg}"}
    when 'INVALID_INVITATION_TOKEN'
      {:code => -8, :message => "Invalid Partecipant Token #{error_msg}"}
    when 'INVALID_FISCAL_CODE'
      {:code => -9, :message => "Invalid value #{error_msg}"}
    when 'WRONG_SURVEY_STATE'
      {:code => -10, :message => "Wrong state provided for survey filtering"}
    when 'CF_UNIQUE_CONSTRAINT'
      {:code => -11, :message => "Unable to add user #{error_msg}"}
    else
      {:code => 100, :message => "Unknow Error"}
    end
  end

  def get_error_http_status(error_code)
    # Gestione errore: a seconda della stringa di errore in arrivo
    # produciamo l'hash errore corretto pronto per essere renderizzato jsonrpc
    case error_code
    when 'INVALID_CREDENTIALS'
      :unauthorized
    when 'MISSING_ARGS'
      :bad_request
    when 'USER_NOT_FOUND'
      :not_found
    when 'EXPIRED_TOKEN'
      :unauthorized
    when 'INVALID_TOKEN'
      :unauthorized
    when 'INVALID_TOKEN_DATA'
      :unauthorized
    when 'SURVEY_NOT_FOUND'
      :not_found
    when 'INVALID_SURVEY'
      :bad_request
    when 'MALFORMED_USER_DATA'
      :bad_request
    when 'MISSING_USER_DATA'
      :bad_request
    when 'INVALID_INVITATION_TOKEN'
      :bad_request
    when 'WRONG_SURVEY_STATE'
      :bad_request
    when 'INVALID_FISCAL_CODE'
      :bad_request
    when 'CF_UNIQUE_CONSTRAINT'
      :bad_request
    else
      :internal_server_error
    end
  end

  def generate_jsonrpc_response(content)
    # Restituisce un oggetto jsonrpc pronto per essere renderizzato
    # content può essere una stringa, un array o un hash
    JsonRpcObjects::V20::Response::create(content).to_json
  end

  def generate_jwt(user_pon_id)
    require 'jwt'
    hmac_secret = Rails.application.config.jwt_secret
    hmac_algotithm = Rails.application.config.jwt_algorithm
    issuer = Rails.application.config.jwt_issuer

    payload = {
        :exp => (Time.now + 1.day).to_i,
        :iss => issuer,
        :pon_id => user_pon_id
    }

    JWT.encode payload, hmac_secret, hmac_algotithm
  end

  def authorize_jwt(token)
    # Il metodo authorize_jwt è di tipo lancia e dimentica:
    # Se viene rilevato qualsiasi errore, viene rilanciata una eccezione
    # che si propagherà fino all'endpoint
    require 'jwt'
    hmac_secret = Rails.application.config.jwt_secret
    hmac_algotithm = Rails.application.config.jwt_algorithm
    issuer = Rails.application.config.jwt_issuer

    decode_options = {
        exp_leeway: 30, # secondi di tolleranza
        algorithm: hmac_algotithm,
        iss: issuer
    }

    begin
      decoded_token = JWT.decode token, hmac_secret, true, decode_options
    rescue JWT::ExpiredSignature
      raise JwtError, 'EXPIRED_TOKEN'
    rescue JWT::InvalidIssuerError, JWT::DecodeError
      raise JwtError, 'INVALID_TOKEN'
    end

    # Controlliamo il pon_id fornito nel payload
    payload = decoded_token[0]
    pon_id = payload["pon_id"]

    unless Pon.find_by_id(pon_id)
      # Restituiamo errore se il pon id non esiste
      raise JwtError, 'INVALID_TOKEN_DATA'
    end

    # Tutti i controlli andati a buon fine
    true

  end

  def check_survey_validity(iSurveyId)
    # Il metodo solleverà eccezione se il sondaggio non viene trovato o non è
    # di tipo richiesto "sondaggio_esterno", altrimenti restituisce il poll specificato
    begin
      poll = Poll.find(iSurveyId)
    rescue ActiveRecord::RecordNotFound
      raise GenericError, 'SURVEY_NOT_FOUND'
    end

    unless poll.sondaggio_esterno
      raise GenericError, 'INVALID_SURVEY'
    end

    poll
  end

  def check_fiscal_code_unique(user_data)
    user = User.find_by email: user_data["email"]

    unless user.nil?
      raise GenericError.new('CF_UNIQUE_CONSTRAINT', "#{user_data["email"]}: this address is already bound to fiscal code #{user.cod_fiscale}") if user.cod_fiscale != user_data["fiscalCode"]
    end
  end

  def user_already_present?(user_data)
    check_fiscal_code_unique(user_data)

    user = User.find_by cod_fiscale: user_data["fiscalCode"]

    if user.nil?
      false
    else
      true
    end
  end

  def update_user_data(user_data)
    # è possibile aggiornare la username senza vincoli
    # è possibile aggiornare l'indirizzo email a patto che non sia già stato associato ad altri utenti
    # (vincolo UNIQUE su tabella database)
    # NON è possibile aggiornare il codice fiscale.
    user = User.find_by(cod_fiscale: user_data["fiscalCode"])
    user.update!(email: user_data["email"], username: "#{user_data["name"]} #{user_data["lastname"]}", confirmed_at: Time.current)
    user
  end

  def get_answers_object(poll_questions_ids, voter)
    raw_answers = []

    poll_questions_ids.each do |question_id|
      author_answers = Poll::Answer.where(question_id: question_id).where(author_id: voter.user_id)

      # Le risposte possono essere più di una per una singola domanda, ciclo tra le risposte
      author_answers.each do |author_answer|
        raw_answers.push(author_answer)
      end

    end

    # Eseguo la mappatura secondo l'oggetto che mi serve
    mapped_answers = []

    raw_answers.each do |answer|
      # Ricavo il testo della domanda:
      question_text = Poll::Question.find(answer.question_id).title
      mapped_answers.push({
                              sQuestion: question_text,
                              sAnswer: answer.answer
                          })
    end

    mapped_answers
  end

  def validate_survey_state(state)
    # Verifichiamo che il parametro state ricada nei valori consentiti:
    # "current", "expired" o "incoming"

    # Se il parametro non è presente, restituiamo true
    unless state.present?
      return true
    end

    if state.include? "current" or state.include? "expired" or state.include? "incoming"
      return true
    end

    false

  end

  def check_blank_args(**args)
    args.each do |arg_name, arg_value|
      raise ArgumentError, "`#{arg_name}` cannot be empty" if arg_value.blank?
    end
  end

  def email_valid?(email)
    regex_pattern = /^(.+)@(.+)\.(.+)$/

    email =~ regex_pattern

  end
end
