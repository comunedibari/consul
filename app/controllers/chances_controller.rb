class ChancesController < Legislation::ProcessesController
    include ServiceFlags
    service_flag :chances

    #has_filters %w{opens next past bis}, only: [:index, :oportunities ]
    has_filters %w{opens next past}, only: [:index, :oportunities ]

    #add chances breadcrumb
    add_breadcrumb I18n.t("breadcrumbs.services.chances"), :chances_path

    def process_type
        [3,5]
    end


end
