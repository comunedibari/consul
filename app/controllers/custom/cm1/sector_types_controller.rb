class SectorTypesController < ApplicationController

  include ServiceFlags
  include FlagActions

  load_and_authorize_resource :sector_type
  skip_authorization_check 

  # add terzo settore breadcrumb
  add_breadcrumb I18n.t("breadcrumbs.services.sectors"), :sector_types_path

  def index
      @sector_types = SectorType.all
      #logger.debug "SONO NEL CONTROLLER DI sector_type +++++++++++++++++++++++++++++++++++++++++++"
      @sector_types.each do |sector_type|
        logger.debug "sector_type= "+ sector_type.name.to_s
      end
  end

end
