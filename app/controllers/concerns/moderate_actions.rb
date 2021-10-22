module ModerateActions
  extend ActiveSupport::Concern
  include Polymorphic
  include NotificationsHelper

  def index
    @resources = @resources.send(@current_filter)
                           .send("sort_by_#{@current_order}")
                           .page(params[:page])
                           .per(50)
    set_resources_instance
  end

  def hide
    hide_resource resource
  end

  # entra sempre quando esamina/nascondi dal moderatore
  def moderate
    #logger.debug "---------------moderate"
    flag=true
    #send_notification
    set_resource_params
    @resources = @resources.with_hidden.where(id: params[:resource_ids])
    # nascondi la risorsa

    if params[:hide_resources].present?
      @resources.accessible_by(current_ability, :hide).each {|resource| hide_resource resource}
      flag=false

    # approva la risorsa
    elsif params[:ignore_flags].present?
      @resources.accessible_by(current_ability, :ignore_flag).each(&:ignore_flag)
      @resources.accessible_by(current_ability, :ignore_flag_appr).each {
        |resource|
        check_reset_flags_count resource

        send_notification_tags(@resToPush)
        if resource.class.name == "Comment"
          if (resource.flags_count == 0)
            add_notification resource
          else
          end
        end
      }
      flag=true

    elsif params[:block_authors].present?
      logger.info "--------------block_authors"
      author_ids = @resources.pluck(author_id).uniq
      User.where(id: author_ids).accessible_by(current_ability, :block).each {|user| block_user user}

    elsif params[:confirm_process].present? || params[:confirm_agreement].present?
      logger.info "--------------confirm_process"
      @resources.accessible_by(current_ability, :ignore_flag_appr).each {
        |resource|
        check_reset_flags_count resource

        send_notification_tags(@resToPush)
      }
    end

    if params[:hide_resources].present?
      logger.info "--------------hide_resources"
      @resources.accessible_by(current_ability, :confirm_hide).each {|resource|
        if resource.try(:flags_count) and resource.flags_count == -2 #&& !resource.hidden_at
          confirm_hide_resource resource
        end
      }
      flag=false
    end
    if @resources[0].respond_to?('restore_event')
      logger.info "--------------restore_event"
      @resources.each do |res|
        res.restore_event(flag)
      end
    end
    redirect_to request.query_parameters.merge(action: :index)
  end

  private

=begin
    def send_notification
      logger.debug "-----send_notification--------- "
      @notification = ProposalNotification.new(proposal_id: 78,title: 'Prova invio', body: 'Proposta rigettata dal moderatore',author_id: 5)
      @proposal = Proposal.with_hidden.find(78)
      if @notification.save
        logger.debug "-----send_notification_save--------- "
        Notification.add(@proposal.author, @notification)
      end
    end
=end
  def add_notification(resource)
    notifiable = resource.reply? ? resource.parent : resource.commentable
    notifiable_author_id = notifiable.try(:author_id)
    if notifiable_author_id.present? && notifiable_author_id != resource.author_id
      Notification.add(notifiable.author, notifiable)
    end
  end

    def send_notification_tags(resource)
      if resource.class.name != "Comment"
        send_notification_for_tags(resource)
      end
    end

    def load_resources
      @resources = resource_model.accessible_by(current_ability, :moderate)
    end

    # approva
    def check_reset_flags_count(resource)
      resource.reset_flags_count
      @resToPush = resource
    end

    # nascondi
    def hide_resource(resource)
      resource.hide
      Activity.log(current_user, :hide, resource)
    end

    def confirm_hide_resource(resource)
      resource.confirm_hide
      Activity.log(current_user, :confirm_hide, resource)
    end

    def block_user(user)
      user.block
      Activity.log(current_user, :block, user)
    end

    def set_resource_params
      params[:resource_ids] = params["#{resource_name}_ids"]
      params[:hide_resources] = params["hide_#{resource_name.pluralize}"]
    end

    def author_id
      :author_id
    end

end
