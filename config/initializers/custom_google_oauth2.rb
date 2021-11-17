module OmniAuth
  module Strategies
    class GoogleOauth2
      USER_INFO_URL = 'https://www.googleapis.com/oauth2/v3/userinfo'

      option :client_options, {
          :site          => 'https://oauth2.googleapis.com',
          :authorize_url => 'https://accounts.google.com/o/oauth2/auth',
          :token_url     => '/token'
      }

      # Aggiorno gli "iss" della verifica token con gli allowed_issuers
      def authorize_params
        super.tap do |params|
          options[:authorize_options].each do |k|
            params[k] = request.params[k.to_s] unless [nil, ''].include?(request.params[k.to_s])
          end

          raw_scope = params[:scope] || DEFAULT_SCOPE
          scope_list = raw_scope.split(" ").map {|item| item.split(",")}.flatten
          scope_list.map! { |s| s =~ /^https?:\/\// || BASE_SCOPES.include?(s) ? s : "#{BASE_SCOPE_URL}#{s}" }
          params[:scope] = scope_list.join(" ")
          params[:access_type] = 'offline' if params[:access_type].nil?
          params['openid.realm'] = params.delete(:openid_realm) unless params[:openid_realm].nil?

          session['omniauth.state'] = params[:state] if params['state']
        end
      end

      uid { raw_info['sub'] || verified_email }

      info do
        prune!({
                   :name       => raw_info['name'],
                   :email      => verified_email,
                   :first_name => raw_info['given_name'],
                   :last_name  => raw_info['family_name'],
                   :image      => image_url,
                   :urls => {
                       'Google' => raw_info['profile']
                   }
               })
      end

      extra do
        hash = {}
        hash[:id_token] = access_token['id_token']

        if !options[:skip_jwt] && !access_token['id_token'].nil?

          hash[:id_info] = JWT.decode(
              access_token['id_token'], nil, false, {
              :verify_iss => true,
              'iss' => 'https://accounts.google.com',
              :verify_aud => true,
              'aud' => options.client_id,
              :verify_sub => false,
              :verify_expiration => true,
              :verify_not_before => true,
              :verify_iat => true,
              :verify_jti => false,
              :leeway => options[:jwt_leeway]
          }).first

      end

        hash[:raw_info] = raw_info unless skip_info?
        hash[:raw_friend_info] = raw_friend_info(raw_info['sub']) unless skip_info? || options[:skip_friends]
        hash[:raw_image_info] = raw_image_info(raw_info['sub']) unless skip_info? || options[:skip_image_info]
        prune! hash
      end

      # Cambio la url per usare la nuova versione
      def raw_info
        @raw_info ||= access_token.get(USER_INFO_URL).parsed
      end

      def verify_hd(access_token)
        return true unless options.hd
        @raw_info ||= access_token.get(USER_INFO_URL).parsed
        allowed_hosted_domains = Array(options.hd)

        raise CallbackError.new(:invalid_hd, "Invalid Hosted Domain") unless allowed_hosted_domains.include? @raw_info['hd']
        true
      end

      # Personalizziamo la callback_url così da non farla generare in maniera automatica (erroneamente) alla gemma
      # def callback_url
      #   Rails.application.config.google_oauth2_callback
      # end

    end
  end
end
