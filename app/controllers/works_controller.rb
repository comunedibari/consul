class WorksController < Legislation::ProcessesController
    include ServiceFlags
    service_flag :works

    #has_filters %w{opens next past sgap}, only: [:index, :oportunities ]
    has_filters %w{opens planned past}, only: [:index, :oportunities ]

    #add lavori pubblici breadcrumb
    add_breadcrumb I18n.t("breadcrumbs.services.works"), :works_path
    
    def process_type
        [2,4]
    end


end
