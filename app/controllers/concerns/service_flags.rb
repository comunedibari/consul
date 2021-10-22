module ServiceFlags
  extend ActiveSupport::Concern

  class_methods do
    def service_flag(name, *options)
      before_action(*options) do
=begin        
        if current_user and !Setting.where(pon_id: current_user.pon_id).where(key: "service.#{name}").first.editable
          raise ServiceDisabled, name
        elsif !Setting.where(pon_id: User.pon_id).where(key: "service.#{name}").first.editable
          raise ServiceDisabled, name
        els
=end        
        if current_user and current_user.administrator?
          true #modifica disattivata => consente accesso a servizio disattivato all'utente amministratore
          #check_service_flag(name)
        else
          check_service_flag(name)
        end
      end
    end
  end

  def check_service_flag(name)
      raise ServiceDisabled, name unless Setting["service.#{name}",User.pon_id]
  end

  class ServiceDisabled < Exception
    def initialize(name)
      @name = name
    end

    def message
      "Service disabled: #{@name}"
    end
  end
end
