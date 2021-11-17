class BookingManager::ModerableBookingsController < ApplicationController

  #skip_authorization_check

  include NotificationsHelper

  before_action :authenticate_user!, only: :create
  before_action :load_data, only: [:show]


  load_and_authorize_resource :asset
  load_and_authorize_resource :moderable_booking, class: "BookingManager::ModerableBooking" , through: :asset

  respond_to :html, :js


  def new
  end

  def index
  end

  def show
  end

  def edit
  end

  def create
    @moderable_booking = BookingManager::ModerableBooking.new
    @moderable_booking.bookable_id = @asset.id
    @moderable_booking.booker_id = @current_user.id
    @moderable_booking.status = 1
    if params[:booking_manager_moderable_booking][:data_f].present? && params[:booking_manager_moderable_booking][:time_start_f].present? && params[:booking_manager_moderable_booking][:time_end_f].present? 
      @moderable_booking.time_start = Time.parse(params[:booking_manager_moderable_booking][:data_f] + ' ' + params[:booking_manager_moderable_booking][:time_start_f])
      @moderable_booking.time_end = Time.parse(params[:booking_manager_moderable_booking][:data_f] + ' ' + params[:booking_manager_moderable_booking][:time_end_f]) - 1.seconds
    end

    begin
      val = @current_user.book! @asset, time_start: @moderable_booking.time_start, time_end: @moderable_booking.time_end, amount: 1
      @moderable_booking.booking_id = val.id
    rescue => exception
      redirect_to new_asset_booking_manager_moderable_booking_path(@asset, @moderable_booking),  :flash => { :alert =>t('admin.asset.create.availabilityError')}
    end

    if val
      if @moderable_booking.save()
        notice = t('admin.booking.create.success')
        redirect_to asset_path(@asset),  notice: notice
      else
        flash.now[:alert] = t('admin.booking.create.error')
        redirect_to new_asset_booking_manager_moderable_booking_path(@asset, @moderable_booking),  :flash => { :alert =>t('admin.asset.create.availabilityError')}
      end
    end
    

  end

  def retire
    if valid_retired_params? && @moderable_booking.update(retired_params.merge(retired_at: Time.current))
      #redirect_to asset_booking_manager_moderable_booking_path(asset_id: @moderable_booking.bookable_id,id: @moderable_booking.id), notice: t('moderable_bookings.notice.retired')
      redirect_to user_path(@moderable_booking.booker_id,filter: 'moderable_bookings')
    else
      render action: :retire_form
    end
  end

  def retire_form
    BookingManager::Booking.destroy(@moderable_booking.booking_id)
    @moderable_booking.update_attribute(:status, 3)
  end

  private

  def send_notification_tags(resource)
    send_notification_for_tags(resource)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_moderable_booking
    @moderable_booking = BookingManager::ModerableBooking.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def moderable_booking_params
    params.require(:booking_manager_moderable_booking).permit(:bookable_id,
                                                              :bookable_type,
                                                              :booker_id,
                                                              :booker_type,
                                                              :amout,
                                                              :data_f,
                                                              :time_start_f,
                                                              :time_end_f,
                                                              :created_at,
                                                              :social_access, #Identificazione Social
                                                              social_content_attributes: [:social_access], #Identificazione Social
                                                              assets_attributes: [:id])
  end

  def retired_params
    params.require(:booking_manager_moderable_booking).permit(:retired_reason, :retired_explanation)
  end

  def valid_retired_params?
    @moderable_booking.errors.add(:retired_reason, I18n.t('errors.messages.blank')) if params[:booking_manager_moderable_booking][:retired_reason].blank?
    @moderable_booking.errors.add(:retired_explanation, I18n.t('errors.messages.blank')) if params[:booking_manager_moderable_booking][:retired_explanation].blank?
    @moderable_booking.errors.empty?
  end


  # def load_retired
  #   if params[:retired].present?
  #     @resources = @resources.retired
  #     @resources = @resources.where(retired_reason: params[:retired]) if Proposal::RETIRE_OPTIONS.include?(params[:retired])
  #   else
  #     @resources = @resources.not_retired
  #   end
  # end

  def load_data
    @moderable_booking = BookingManager::ModerableBooking.all.where("booking_id = ?",params[:id]).where("bookable_id = ?",params[:asset_id]).first
    @asset = Asset.with_hidden.find_by(id: @moderable_booking.bookable_id)
  end


end
