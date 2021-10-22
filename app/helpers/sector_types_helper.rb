module SectorTypesHelper




def sector_types_image_url (type_name)
    image_url= "/assets/sector_types/#{type_name}.png"
end

def sectors_by_sector_type_id( sector_type_id)
    sectors = Sector.where("sector_type_id = ?", sector_type_id).where(visible: true)
    sectors.count

end

def sector_types_all
    sector_types_name = Array.new
    sector_types = SectorType.all
    selected = nil
    sector_types.each do |type|
      sector_types_name.push([type.name,type.id])
      if type.name.downcase.include? "altro" or type.name.downcase.include? "altre"
        selected = type.id
      end
    end
    options_for_select(sector_types_name,selected)
end















end
