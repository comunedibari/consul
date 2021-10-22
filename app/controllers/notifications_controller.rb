class NotificationsController < ApplicationController
  include CustomUrlsHelper

  before_action :authenticate_user!
  skip_authorization_check

  respond_to :html, :js

  def index
    @notifications = current_user.notifications.unread
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read
    redirect_to linkable_resource_path(@notification)
  end

  def read
    @notifications = current_user.notifications.read
  end

  def mark_all_as_read
    current_user.notifications.unread.each {|notification| notification.mark_as_read}
    redirect_to notifications_path
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read
  end

  def mark_as_unread
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_unread
  end

  private

  def linkable_resource_path(notification)
    case notification.linkable_resource.class.name
    when "Budget::Investment"
      budget_investment_path @notification.linkable_resource.budget, @notification.linkable_resource
    when "Legilsation::Proposal"
      legislation_process_proposal_path @notification.linkable_resource.process, @notification.linkable_resource
    when "Legilsation::Process"
      legislation_process_path @notification.linkable_resource
    when "Collaboration::Agreement"
      collaboration_agreement_path @notification.linkable_resource
    when "BookingManager::ModerableBooking"
      asset_booking_manager_moderable_booking_path @notification.linkable_resource.asset, @notification.linkable_resource
    when "Topic"
      community_topic_path @notification.linkable_resource.community, @notification.linkable_resource
    when "Sector"
      moderation_sectors_path
    when "StSector"
      sector_path(@notification.linkable_resource.sector.id, st:@notification.linkable_resource.id)
    when "JobLogs"
      admin_sectors_path
    else
      url_for @notification.linkable_resource
    end
  end

end
