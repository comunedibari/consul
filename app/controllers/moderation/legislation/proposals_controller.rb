class Moderation::Legislation::ProposalsController < Moderation::BaseController
  include ModerateActions
  #include FeatureFlags
  include ServiceFlags

  has_filters %w{new_hidden pending_flag_review all_moderate with_ignored_flag}, only: :index
  has_orders %w{flags created_at}, only: :index


  before_action :load_resources, only: [:index, :moderate]
  #after_action :send_notification, only: [:moderate]

  load_and_authorize_resource

  private

  def load_resources
    @resources = resource_model.where("moderation_entity in (1,2) or moderation_entity is NULL")
  end
  
  def resource_model
    ::Legislation::Proposal
  end

  def resource_name
    "legislation_proposal"
  end

end
