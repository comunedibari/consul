module ActsAsTaggableOn

  Tagging.class_eval do

    after_create :increment_tag_custom_counter
    after_destroy :touch_taggable, :decrement_tag_custom_counter

    scope :public_for_api, -> do
      where(%{taggings.tag_id in (?) and
              (taggings.taggable_type = 'Debate' and taggings.taggable_id in (?)) or
              (taggings.taggable_type = 'Event' and taggings.taggable_id in (?)) or
              (taggings.taggable_type = 'Asset' and taggings.taggable_id in (?)) or
              (taggings.taggable_type = 'Reporting' and taggings.taggable_id in (?)) or    #mia
              (taggings.taggable_type = 'Proposal' and taggings.taggable_id in (?)) or
              (taggings.taggable_type = 'Crowdfunding' and taggings.taggable_id in (?)) },
            Tag.where('kind IS NULL or kind = ?', 'category').pluck(:id),
            Debate.public_for_api.pluck(:id),
            Event.public_for_api.pluck(:id),
            Asset.public_for_api.pluck(:id),
            Reporting.public_for_api.pluck(:id),		#mia
            Proposal.public_for_api.pluck(:id),
            Crowdfunding.public_for_api.pluck(:id))

    end

    def touch_taggable
      taggable.touch if taggable.present?
    end

    def increment_tag_custom_counter
      tag.increment_custom_counter_for(taggable_type)
    end

    def decrement_tag_custom_counter
      tag.decrement_custom_counter_for(taggable_type)
    end
  end

  Tag.class_eval do

     
    scope :category, -> { where(kind: "category") }
    
    validates :name, presence: true,
                    length: { minimum: 2 }

    def category?
      kind == "category"
    end

    include Graphqlable

    scope :public_for_api, -> do
      where('(tags.kind IS NULL or tags.kind = ?) and tags.id in (?)',
            'category',
            Tagging.public_for_api.pluck('DISTINCT taggings.tag_id'))
    end

    include PgSearch

    pg_search_scope :pg_search, against: :name,
                                using: {
                                  tsearch: {prefix: true}
                                },
                                ignoring: :accents

    def self.search(term)
      pg_search(term)
    end

    def increment_custom_counter_for(taggable_type)
      Tag.increment_counter(custom_counter_field_name_for(taggable_type), id)
    end

    def decrement_custom_counter_for(taggable_type)
      Tag.decrement_counter(custom_counter_field_name_for(taggable_type), id)
    end

    def recalculate_custom_counter_for(taggable_type)
      visible_taggables = taggable_type.constantize.includes(:taggings).where('taggings.taggable_type' => taggable_type, 'taggings.tag_id' => id)

      update(custom_counter_field_name_for(taggable_type) => visible_taggables.count)
    end

    def self.category_names
      Tag.category.pluck(:name)
    end

    def self.spending_proposal_tags
      ActsAsTaggableOn::Tag.where('taggings.taggable_type' => 'SpendingProposal').includes(:taggings).order(:name).uniq
    end

    def self.graphql_field_name
      :tag
    end

    def self.graphql_pluralized_field_name
      :tags
    end

    def self.graphql_type_name
      'Tag'
    end

    private

      def custom_counter_field_name_for(taggable_type)
        "#{taggable_type.underscore.pluralize}_count"
      end
  end

end
