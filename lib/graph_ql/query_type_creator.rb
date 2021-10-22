require 'graphql'

module GraphQL
  class QueryTypeCreator

    def self.create(api_types)
      GraphQL::ObjectType.define do
        name 'QueryType'
        description 'The root query for the schema'

        api_types.each do |model, created_type|
          if created_type.fields['id']
            field model.graphql_field_name do
              type created_type
              description model.graphql_field_description
              argument :id, !types.ID
              resolve ->(object, arguments, context) { model.public_for_api.find_by(id: arguments['id'])}
            end
          end

          connection(model.graphql_pluralized_field_name, created_type.connection_type, max_page_size: 50, complexity: 1000) do
            description model.graphql_pluralized_field_description
            argument :ids, types[types.ID], "The IDs of the proposals"
            argument :pon_id, types.ID, "The ID of pon"
            # argument :editable, types[types.Boolean], "The Editable of settings"
            # argument :key, types.String, "Key of settings"
            resolve ->(object, arguments, context) do
              if arguments[:pon_id]
                model.public_for_api.where(pon_id: arguments[:pon_id])
              elsif arguments[:ids]
                model.public_for_api.where(id: arguments[:ids])
              # elsif arguments[:editable]
              #   model.public_for_api.where(editable: arguments[:editable])
              # elsif arguments[:key]
              #   model.public_for_api.where("key LIKE :key1 ",{:key1 => arguments[:key]+"%"}).enabled
              else
                model.public_for_api
              end
            end
          end

        end
      end
    end

  end
end
