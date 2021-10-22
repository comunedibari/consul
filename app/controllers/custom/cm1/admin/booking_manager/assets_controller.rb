class Admin::BookingManager::AssetsController < Admin::BookingManager::BaseController

  include NotificationsHelper

  skip_authorization_check
  load_and_authorize_resource :asset, class: "::Asset"
  before_action :load_asset, only: [:show, :edit, :update, :destroy]
  #before_action :update_availability, only: [:set_rule]
  before_action :load_categories, only: [:index, :new, :create, :edit, :map, :summary] #miaaa

  def verify_administrator
    raise CanCan::AccessDenied unless current_user.present?
  end

  def index
    @assets = Asset.by_user_pon.sort_by_newest
    @assets = @assets.page(params[:page])
  end

  def show
    if @asset.schedule.to_hash[:rrules].count > 0
      occurences = @asset.schedule.occurrences_between(Date.current, Date.current + 6.months)
      #reservation = @asset.bookings.where("time_start > ?",(Date.current - 1.days).end_of_day)
      reservation = @asset.moderable_bookings.where("time_start > ?", (Date.current - 1.days).end_of_day).where(status: [1, 2])
      data = all_data_for_calendar(occurences, reservation)
    else
      data = Array.new
    end

    respond_to do |format|
      format.json {render json: data.to_json}
      format.html
    end

  end

  def new
    #@asset = Asset.new

  end

  def edit
    #load_asset_availability
    #self.get_all_occurence
    #self.set_recurrence_rule
    #::BookingManager::ModerableBooking.book!(@current_user, @asset)

    #self.get_all_occurence

    #rescue Exception => ex
    # puts "*******************" + ex.to_s + "*********************"
  end

  def create
    @asset = Asset.new(asset_params.merge(author: current_user, pon_id: current_user.pon_id))
    @asset.schedule = IceCube::Schedule.new(Time.now.beginning_of_day + 1.days, duration: 30.minutes)
    @asset.capacity = 1

    if @asset.save

      if asset_params[:social_access].to_i > 0
        SocialContent.create(sociable: @asset, social_access: true)
      else
        SocialContent.create(sociable: @asset, social_access: false)
      end

      notice = t("admin.asset.create.create_success")
      send_notification_tags(@asset)
      #mi reindirizza alla pagina http://localhost:3000/admin/legislation/processes/24/edit
      redirect_to admin_asset_path(@asset), notice: notice
    else
      flash.now[:error] = t('admin.asset.create.error')
      #se non va bene con il "render" vado quà http://localhost:3000/admin/legislation/processes
      render :new
    end
  end

  def update
    if @asset.update(asset_params)
      link = edit_admin_asset_path(@asset).html_safe
      set_tag_list
      if current_user.provider == "openam" || current_user.administrator?

        # Bugfix: params[:asset][:social_content] potrebbe essere NIL
        unless params[:asset][:social_content].present?
          redirect_to admin_asset_path(@asset), notice: t("admin.asset.edit.update_success")
          return
        end

        if params[:asset][:social_content][:social_access].present?

          @social_content = SocialContent.where(sociable_type: 'Asset').where(sociable_id: @asset.id).first
          if params[:asset][:social_content][:social_access].to_i > 0
            @social_content.update_attribute(:social_access, true)
          else
            @social_content.update_attribute(:social_access, false)
          end

          redirect_to admin_asset_path(@asset), notice: t("admin.asset.edit.update_success")
          return
        end

      end

    else
      flash.now[:error] = t('admin.asset.create.error')
      #altrimenti ritorno alla pagina di modifica
      render :edit
    end
  end

  def destroy
    @asset = Asset.find(params[:id])
    if @asset.moderable_bookings.approved.count == 0
      @asset.destroy
      notice = t('admin.asset.destroy.notice')
      redirect_to admin_assets_path, notice: notice
    else
      #flash.now[:error] = t('admin.asset.destroy.error')
      redirect_to admin_assets_path, flash: {error: t('admin.asset.destroy.error')}
    end
  end

  def social_flag
    @asset = Asset.find_by(id: params[:id])
    @asset.social_content.social_access = !@asset.social_content.social_access
    @asset.social_content.save
    @asset.touch
    redirect_to :back, notice: t('notice.operaction_successfull')
  end


  def set_rule
    @asset.schedule = IceCube::Schedule.new(Time.now.beginning_of_day, duration: 30.minutes)
    month = availability_params[:month].split(",").map {|s| s.to_i}

    availability_params[:days].each do |day|
      slot = day[1]
      s_key = slot.keys
      (0..2).step(2).each do |i|
        time_from = slot[s_key[i]]
        time_to = slot[s_key[i + 1]]
        unless (time_from.empty? && time_to.empty?)
          time_from = time_from.split(":").map {|s| s.to_i}
          time_to = time_to.split(":").map {|s| s.to_i}
          if (time_from[1] == 30)
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(day[0].to_sym).month_of_year(month).hour_of_day(time_from[0]).minute_of_hour(30))
            time_from[0] += 1
          end
          if (time_to[1] == 29)
            hours_range = (time_from[0]..time_to[0]).to_a
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(day[0].to_sym).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30))
          end
          if (time_to[1] == 59)
            hours_range = (time_from[0]..time_to[0]).to_a
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(day[0].to_sym).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30))
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(day[0].to_sym).month_of_year(month).hour_of_day(time_to[0]).minute_of_hour(0))

          end
        end
      end
    end
    @asset.save!
  end

  private

  def send_notification_tags(resource)
    send_notification_for_tags(resource)
  end

  # Use callbacks to share common setup or constraints between actions.
  def load_asset
    @asset = Asset.find(params[:id])
  end

  def load_availability
    if (Availability.where(asset_id: @asset.id).present?)
      @availability = Availability.findForAsset(@asset.id)
    else
      (1..7).each do
        @availability = Availability.new(asset_id: @asset.id)
        @availability.save
      end
      @asset.availability.each do |a|
        (1..2).each do
          AvailabilityDay.create(availability_id: a.id)
        end
      end
    end
  end

  def update_availability
    @availability = Availability.new(availability_params)
    unless @availability.valid?
      flash.now[:error] = t('admin.asset.create.error')
      render :show
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def asset_params

    params.require(:asset).permit(
      :name,
      :description,
      :address,
      :contacts,
      :skip_map,
      :custom_list,
      :tag_list,
      :social_access,
      map_location_attributes: [:latitude, :longitude, :zoom],
      images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
      social_content_attributes: [:social_access],
      documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy]
    )
  end

  def set_tag_list
    @asset.set_tag_list_on(:customs, asset_params[:custom_list])
    @asset.save
  end

  def availability_params
    params.require(:availability).permit(
      :month,
      days: [monday: [:am_start, :am_end, :fm_start, :fm_end], tuesday: [:am_start, :am_end, :fm_start, :fm_end], wednesday: [:am_start, :am_end, :fm_start, :fm_end], thursday: [:am_start, :am_end, :fm_start, :fm_end], friday: [:am_start, :am_end, :fm_start, :fm_end], saturday: [:am_start, :am_end, :fm_start, :fm_end]]
    )
  end


  def destroy_map_location_association
    map_location = params[:asset][:map_location_attributes]
    if map_location && (map_location[:longitude] && map_location[:latitude]).blank? && !map_location[:id].blank?
      MapLocation.destroy(map_location[:id])
    end
  end

  def load_categories
    @categories = ActsAsTaggableOn::Tag.category.order(:name)
  end

  def all_data_for_calendar occurrences, reservations

    date_format = '%Y-%m-%dT%H:%M'
    duration = @asset.schedule.duration
    all_data = Array.new

    occurrences.each do |slot|
      all_data.push({
                      title: "",
                      start: slot.strftime(date_format),
                      end: (slot + @asset.schedule.duration).strftime(date_format),
                      allDay: false,
                      color: 'green',
                      #user: 0,
                      #backgroundColor: 'green',
                      rendering: 'background'
                    })
    end

    reservations.each do |reservation|
      time_end = reservation.time_end + 1.seconds

      all_data.push({
                      title: "",
                      start: reservation.time_start.strftime(date_format),
                      end: time_end.strftime(date_format),
                      allDay: false,
                      color: reservation.status == 1 ? 'orange' : 'red',
                      id: reservation.id,
                      #link:
                      #rendering: 'background'
                    })
    end

    all_data
  end

end
