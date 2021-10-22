class Moderation::CommentsController < Moderation::BaseController
  include ModerateActions

  has_filters %w{new_hidden pending_flag_review all_moderate with_ignored_flag}, only: :index
  has_orders %w{flags newest}, only: :index

  before_action :load_resources, only: [:index, :moderate]

  load_and_authorize_resource

  private

    def load_resources
        @resources = resource_model.where("moderation_entity in (1,2,3) or moderation_entity is NULL").by_comment_pon
    end

    def resource_model
      Comment
    end

    def author_id
      :user_id
    end
end
