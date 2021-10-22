class ApiService < ActiveRecord::Base
    include Graphqlable
    self.table_name = "api_services"

    belongs_to :setting
    belongs_to :pon
    scope :public_for_api, -> { joins(:setting).where("settings.value = 'true'") }


    attr_accessor :service_summ

    def service_summ
        if service_title.start_with?('Discussione informata')
            service_summ = Setting.where(key: 'service_description.debates').where(pon_id: pon_id).first
            service_summ.value
        elsif service_title.start_with?('Prenotazioni')
            service_summ = Setting.where(key: 'service_description.assets').where(pon_id: pon_id).first
            service_summ.value
        elsif service_title.start_with?('Agenda e calendario')
            service_summ = Setting.where(key: 'service_description.events').where(pon_id: pon_id).first
            service_summ.value
        elsif service_title.start_with?('Piattaforma terzo settore')
            service_summ = Setting.where(key: 'service_description.third_sector_platform').where(pon_id: pon_id).first
            service_summ.value 
        elsif service_title.start_with?('Crowdfundings')
            service_summ = Setting.where(key: 'service_description.crowdfundings').where(pon_id: pon_id).first
            service_summ.value
        elsif service_title.start_with?('Consultazione certificata')
            service_summ = Setting.where(key: 'service_description.polls').where(pon_id: pon_id).first
            service_summ.value                                               
        elsif service_title.start_with?('Proposte e iniziative')
            service_summ = Setting.where(key: 'service_description.processes').where(pon_id: pon_id).first
            service_summ.value
        elsif service_title.start_with?('Segnalazioni geolocalizzate')
            service_summ = Setting.where(key: 'service_description.reportings').where(pon_id: pon_id).first
            service_summ.value
        elsif service_title.start_with?('Opportunità')
            service_summ = Setting.where(key: 'service_description.chances').where(pon_id: pon_id).first
            service_summ.value 
        elsif service_title.start_with?('Tracciamento lavori pubblici')
            service_summ = Setting.where(key: 'service_description.works').where(pon_id: pon_id).first
            service_summ.value
        elsif service_title.start_with?('Patto di collaborazione')
            service_summ = Setting.where(key: 'service_description.collaboration').where(pon_id: pon_id).first
            service_summ.value       
        elsif service_title.start_with?('E-petitioning')
            service_summ = Setting.where(key: 'service_description.proposals').where(pon_id: pon_id).first
            service_summ.value                                               
        end
    end

end
