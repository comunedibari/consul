
#moderazione su reporting
class Moderation::ReportingsController < Moderation::BaseController
  include ModerateActions
  #include FeatureFlags
  include ServiceFlags

  has_filters %w{new_hidden pending_flag_review all_moderate with_ignored_flag}, only: :index
  has_orders %w{flags created_at}, only: :index

  service_flag :reportings


  before_action :load_resources, only: [:index, :moderate]
  #after_action :send_notification, only: [:moderate]

  load_and_authorize_resource

  private

  def load_resources
    @resources = resource_model.where("moderation_entity in (1,2,3) or moderation_entity is NULL").by_user_pon
  end
  
  def resource_model
      Reporting
    end

=begin
    def send_notification_old
      logger.debug "-----send_notification--------- "
      @notification = ProposalNotification.new(proposal_id: 78,title: 'Prova invio', body: 'Proposta rigettata dal moderatore')
      @proposal = Proposal.with_hidden.find(78)
      if @notification.save
        Notification.add(@proposal.author, @notification)
      end
    end
=end

end
