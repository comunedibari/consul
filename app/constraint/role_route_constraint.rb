class RoleRouteConstraint
  
    def matches?(request)
        val = request.path_parameters[:process_id]
        if val.nil?
            val = request.path_parameters[:id]
        end
        if !val.nil?
            id = val.split('-')[0].to_i
            if !id.nil?
                items = Legislation::Process.where(id: id)
                items.count > 0 ? items.first.process_type != 1 : false
            else
                false
            end
        else
            false
        end
    end
  
  end