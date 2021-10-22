module ReportingTypesHelper

  #miaa
  def reporting_types_select_options
    ReportingType.all.where("category_id > 0").order(nome: :asc).collect { |t| [ t.nome, t.id ] }
  end

end
