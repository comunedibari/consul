class Admin::BookingManager::ModerableBookingsController < Admin::BookingManager::BaseController

  
  has_filters %w{to_be_approved approved deleted}, only: :index
  
  skip_authorization_check
  load_and_authorize_resource :moderable_booking, class: "::BookingManager::ModerableBooking"
  before_action :load_moderable_booking, only: [:show, :edit, :update, :destroy]


  def index
    @moderable_bookings = ::BookingManager::ModerableBooking.sort_by_newest

    @search = search_params[:search]

    @moderable_bookings = @moderable_bookings.by_user_pon.search(search_params).send(@current_filter).page(params[:page]).order("created_at DESC")
    
    #@moderable_bookings = @moderable_bookings.send(@current_filter).page(params[:page])
  end

  def edit

  end

  def update
    if @moderable_booking.update(moderable_booking_params)
      if  @moderable_booking.status == 3
        BookingManager::Booking.delete(@moderable_booking.booking_id)
      end
      redirect_to  admin_moderable_bookings_path , notice: t("admin.asset.edit.update_success")
    else
      flash.now[:error] = t('admin.asset.create.error')
      #altrimenti ritorno alla pagina di modifica
      render :edit
    end
  end

=begin

  def approve
    if params[:note] != nil 
      @moderable_booking.note = moderable_booking_params[:note]
    end
    @moderable_booking.update_attributes(params[:note])
    self.set_status(2);
    #scegliere dove redirigere
    redirect_to admin_moderable_bookings_path(@asset)
  end

  def disapprove
    if params[:note] != nil 
      @moderable_booking.note = moderable_booking_params[:note]
    end
    @moderable_booking.update_attributes(params[:note].to_h)
    #BookingManager::Booking.destroy(@moderable_booking.booking_id)
    self.set_status(3);
    #scegliere dove redirigere
    redirect_to admin_moderable_bookings_path(@asset)
  end

   def set_status(status)
     @moderable_booking.status = status
     @moderable_booking.save
   end
=end

   def load_moderable_booking
    @moderable_booking = ::BookingManager::ModerableBooking.find(params[:id])
   end  
      
  private  

  def moderable_booking_params
    params.require(:booking_manager_moderable_booking).permit(
      :booking_id,
      :bookable_id,
      :booker_id,
      :time_start,
      :time_end,
      :status,
      :note
    )
  end
 
  def search_params
    params.permit(:bookable_id, :search)
  end

end
