class SectorType < ActiveRecord::Base
    include Rails.application.routes.url_helpers
    #include Mappable
    #include Flaggable
    #include Conflictable
    #include Measurable
    #include Searchable
    #include Filterable
    #include Graphqlable
    #include Communitable
    #include Documentable
    #include Galleryable
    #include Sanitizable
    #include HasPublicAuthor
    #include Graphqlable
    #include Imageable
    #include ActsAsParanoidAliases


    has_many :sectors

    # def sector_types_all
    #     sector_types = Sector_type.all
    #     sector_types.each do |type|
    #       sector_types_name.push(type.name)
    #     end
    #     sector_types_name
    # end

end
