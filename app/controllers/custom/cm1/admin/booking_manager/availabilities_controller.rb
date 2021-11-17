class Admin::BookingManager::AvailabilitiesController < Admin::BookingManager::BaseController

  load_and_authorize_resource :asset
  load_and_authorize_resource :availability, through: :asset
  #load_and_authorize_resource :availability, class: "Admin::BookingManager::Availabilities"

  before_action :set_availability, only: [:show, :show_all, :edit, :update, :destroy]


  # GET /availabilities/1
  # GET /availabilities/1.json
  def show
  end

  # GET /availabilities/new
  def new
    @availability = Availability.new
    12.times {|index| @availability.months.build}
    7.times {|index| @availability.days.build}
  end

  def daily_availability
    @availability = Availability.new
    @availability.years.build
    @availability.months.build
    @availability.days.build
  end

  # GET /availabilities/1/edit
  def edit
  end

  def delete

  end

  # POST /availabilities
  # POST /availabilities.json
  def create
    @availability = Availability.new(availability_params)
    @availability.asset_id = @asset.id
    if @asset.schedule.nil?
      @asset.schedule = IceCube::Schedule.new(Time.now.beginning_of_day, duration: 30.minutes)
    end
    if @availability.valid? && @asset.valid?
      self.set_rule(availability_params)
      redirect_to admin_asset_path(@asset), notice: t('admin.availability.table.new.notice.success')
    else
      render :new
    end
  end

  def create_daily
    @availability = Availability.new(availability_params)
    @availability.asset_id = @asset.id
    if @asset.schedule.nil?
      @asset.schedule = IceCube::Schedule.new(Time.now.beginning_of_day, duration: 30.minutes)
    end
    if @availability.valid? && @asset.valid?
      self.set_daily_rule(availability_params)
      @availability.save
      redirect_to admin_asset_path(@asset), notice: t('admin.availability.table.new.notice.success')
    else
      render :daily_availability
    end
  end

  # PATCH/PUT /availabilities/1
  # PATCH/PUT /availabilities/1.json
  def update
    if @availability.update(availability_params)
      format.html {redirect_to @availability, notice: 'Availability was successfully updated.'}
    else
      format.html {render action: 'edit'}
    end
  end

  # DELETE /availabilities/1
  # DELETE /availabilities/1.json
  def destroy
    #self.unset_rule
    @availability.destroy
    self.unset_rule_new
    @moderable_bookings = BookingManager::ModerableBooking.where(bookable_id: @asset.id).where("status = 2").where("time_start >= ?", Time.now)
    begin
      @moderable_bookings.each do |moderable_booking|
        prenotazione = BookingManager::Booking.find(moderable_booking.booking_id)
        if @asset.schedule.occurs_at?(prenotazione.time_start) == false || @asset.schedule.occurring_at?(prenotazione.time_end - 1.minutes) == false
          add_notification moderable_booking  #aggiunta notifica all'atto dell'eliminazione di una disponibilità
          Mailer.moderable_booking_deleted(moderable_booking).deliver_later #invio email all'utente a cui è stata annullata la prenotazione 
          prenotazione.destroy
          moderable_booking.update_attribute(:status, 3)
        end
      end
      redirect_to admin_asset_path(@asset), notice: t('admin.availability.table.new.notice.moderable_booking_destroy')
    rescue => exception
      redirect_to admin_asset_path(@asset), :flash => {:alert => t('admin.availability.table.new.notice.error')}
    end

  end

  def destroy_daily
    #self.unset_daily_rule
    @availability.destroy
    self.unset_rule_new
    @moderable_bookings = BookingManager::ModerableBooking.where(bookable_id: @asset.id).where("status < 3")
    begin
      @moderable_bookings.each do |moderable_booking|
        add_notification moderable_booking #aggiunta notifica all'atto dell'eliminazione di una disponibilità
        Mailer.moderable_booking_deleted(moderable_booking).deliver_later #invio email all'utente a cui è stata annullata la prenotazione
        prenotazione = BookingManager::Booking.find(moderable_booking.booking_id)
        if @asset.schedule.occurs_at?(prenotazione.time_start) == false || @asset.schedule.occurring_at?(prenotazione.time_end - 1.minutes) == false
          prenotazione.destroy
          moderable_booking.update_attribute(:status, 3)
        end
      end
      redirect_to admin_asset_path(@asset), notice: t('admin.availability.table.new.notice.moderable_booking_destroy')
    rescue => exception
      redirect_to admin_asset_path(@asset), :flash => {:alert => t('admin.availability.table.new.notice.error')}
    end
  end

  def add_notification(moderable_booking)
    notifiable = moderable_booking
    Notification.add(notifiable.user, notifiable)
  end

  def set_daily_rule(params)
    year = availability_params[:years_attributes].first[1][:year].to_i
    month = availability_params[:months_attributes].first[1][:month].to_i
    day = availability_params[:days_attributes].first[1][:day].to_i
    keys = ["am_start", "am_end", "pm_start", "pm_end"]
    (0..2).step(2).each do |i|
      time_start = availability_params[:days_attributes].first[1][keys[i]]
      time_end = availability_params[:days_attributes].first[1][keys[i + 1]]
      unless (time_start.empty? && time_end.empty?)
        time_start = time_start.split(":").map {|s| s.to_i}
        time_end = time_end.split(":").map {|s| s.to_i}

        if (time_start[1] == 30)
          @asset.schedule.add_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(time_start[0]).minute_of_hour(30).day_of_month(day))
          time_start[0] += 1
        end
        if (time_end[1] == 00)
          hours_range = (time_start[0]..(time_end[0] - 1)).to_a
          @asset.schedule.add_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30).day_of_month(day))
        end
        if (time_end[1] == 59)
          hours_range = (time_start[0]..time_end[0]).to_a
          @asset.schedule.add_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30).day_of_month(day))
        end
        if (time_end[1] == 30)
          hours_range = (time_start[0]..(time_end[0] - 1)).to_a
          @asset.schedule.add_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30).day_of_month(day))
          @asset.schedule.add_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(time_end[0]).minute_of_hour(0).day_of_month(day))
        end
      end
      puts ">>>>>>>>>>>>>>>>>year=" + year.to_s + " month=" + month.to_s + " day=" + day.to_s + " time_start=" + time_start.to_s + " time_end=" + time_end.to_s
    end
    @asset.save
  end

  def set_rule(params)
    months = availability_params[:months_attributes].reject {|v, i| i["checked"] == "0"}.map {|v| v[0].to_i + 1}
    days = availability_params[:days_attributes].reject {|v, i| i["am_start"].blank? && i["pm_start"].blank?}.map {|v| v[0].to_i}
    keys = ["am_start", "am_end", "pm_start", "pm_end"]
    days.each do |day|
      (0..2).step(2).each do |i|
        time_start = availability_params[:days_attributes][day.to_s][keys[i]]
        time_end = availability_params[:days_attributes][day.to_s][keys[i + 1]]
        unless (time_start.empty? && time_end.empty?)
          time_start = time_start.split(":").map {|s| s.to_i}
          time_end = time_end.split(":").map {|s| s.to_i}

          if (time_start[1] == 30)
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(day).month_of_year(months).hour_of_day(time_start[0]).minute_of_hour(30))
            time_start[0] += 1
          end
          if (time_end[1] == 00)
            hours_range = (time_start[0]..(time_end[0] - 1)).to_a
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(day).month_of_year(months).hour_of_day(hours_range).minute_of_hour(0, 30))
          end
          if (time_end[1] == 59)
            hours_range = (time_start[0]..time_end[0]).to_a
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(day).month_of_year(months).hour_of_day(hours_range).minute_of_hour(0, 30))
          end
          if (time_end[1] == 30)
            hours_range = (time_start[0]..(time_end[0] - 1)).to_a
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(day).month_of_year(months).hour_of_day(hours_range).minute_of_hour(0, 30))
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(day).month_of_year(months).hour_of_day(time_end[0]).minute_of_hour(0))
          end
        end
      end
    end
    @asset.save
  end

  def unset_daily_rule
    year = Year.where(availability_id: @availability.id).select("year").map {|v| v[:year]}.first
    month = Month.where(availability_id: @availability.id).where(checked: true).select("month").map {|v| v[:month]}.first
    day = Day.where(availability_id: @availability.id).where(" am_start IS NOT NULL OR pm_start  IS NOT NULL").ids.first

    keys = ["am_start", "am_end", "pm_start", "pm_end"]
    (0..2).step(2).each do |i|
      current_day = Day.find(day)
      unless (current_day[keys[i]].nil? && current_day[keys[i + 1]].nil?)
        time_start = current_day[keys[i]].to_s(:time).split(":").map {|s| s.to_i}
        time_end = current_day[keys[i + 1]].to_s(:time).split(":").map {|s| s.to_i}
        if (time_start[1] == 30)
          @asset.schedule.remove_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(time_start[0]).minute_of_hour(30).day_of_month(current_day.day))
          time_start[0] += 1
        end
        if (time_end[1] == 00)
          hours_range = (time_start[0]..(time_end[0] - 1)).to_a
          @asset.schedule.remove_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30).day_of_month(current_day.day))

        end
        if (time_end[1] == 59)
          hours_range = (time_start[0]..time_end[0]).to_a
          @asset.schedule.remove_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30).day_of_month(current_day.day))
        end
        if (time_end[1] == 30)
          hours_range = (time_start[0]..(time_end[0] - 1)).to_a
          @asset.schedule.remove_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30).day_of_month(current_day.day))
          @asset.schedule.remove_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(time_end[0]).minute_of_hour(0).day_of_month(current_day.day))
        end
      end
      puts ">>>>>>>>>>>>>>>>>year=" + year.to_s + " month=" + month.to_s + " day=" + current_day.day.to_s + " time_start=" + time_start.to_s + " time_end=" + time_end.to_s

    end
    @asset.save
  end


  def unset_rule
    months = Month.where(availability_id: @availability.id).where(checked: true).select("month").map {|v| v[:month]}
    days = Day.where(availability_id: @availability.id).where(" am_start IS NOT NULL OR pm_start  IS NOT NULL").ids
    keys = ["am_start", "am_end", "pm_start", "pm_end"]
    days.each do |day|
      #day = days[1]
      (0..2).step(2).each do |i|
        current_day = Day.find(day)
        unless (current_day[keys[i]].nil? && current_day[keys[i + 1]].nil?)
          time_start = current_day[keys[i]].to_s(:time).split(":").map {|s| s.to_i}
          time_end = current_day[keys[i + 1]].to_s(:time).split(":").map {|s| s.to_i}
          if (time_start[1] == 30)
            @asset.schedule.remove_recurrence_rule(IceCube::Rule.daily.day(current_day.day).month_of_year(months).hour_of_day(time_start[0]).minute_of_hour(30))
            time_start[0] += 1
          end
          if (time_end[1] == 00)
            hours_range = (time_start[0]..(time_end[0] - 1)).to_a
            @asset.schedule.remove_recurrence_rule(IceCube::Rule.daily.day(current_day.day).month_of_year(months).hour_of_day(hours_range).minute_of_hour(0, 30))
          end
          if (time_end[1] == 59)
            hours_range = (time_start[0]..time_end[0]).to_a
            @asset.schedule.remove_recurrence_rule(IceCube::Rule.daily.day(current_day.day).month_of_year(months).hour_of_day(hours_range).minute_of_hour(0, 30))
          end
          if (time_end[1] == 30)
            hours_range = (time_start[0]..(time_end[0] - 1)).to_a
            @asset.schedule.remove_recurrence_rule(IceCube::Rule.daily.day(current_day.day).month_of_year(months).hour_of_day(hours_range).minute_of_hour(0, 30))
            @asset.schedule.remove_recurrence_rule(IceCube::Rule.daily.day(current_day.day).month_of_year(months).hour_of_day(time_end[0]).minute_of_hour(0))
          end
        end
      end
    end
    @asset.save
  end

  def unset_rule_new
    @asset.schedule = IceCube::Schedule.new(Time.parse(@asset.created_at.to_s).beginning_of_day + 1.days, duration: 30.minutes)
    @asset.save

    @availabilities = @asset.availabilities
    if @availabilities.weekly.any?
      @availabilities.weekly.each do |availability|
        set_rule_new(availability)
      end
    end

    if @availabilities.daily.any?
      @availabilities.daily.each do |availability|
        set_daily_rule_new(availability)
      end
    end
  end


  def set_rule_new(availability)

    months = Month.where(availability_id: availability.id).where(checked: true).select("month").map {|v| v[:month]}
    days = Day.where(availability_id: availability.id).where(" am_start IS NOT NULL OR pm_start  IS NOT NULL").ids
    keys = ["am_start", "am_end", "pm_start", "pm_end"]
    days.each do |day|
      #day = days[1]
      (0..2).step(2).each do |i|
        current_day = Day.find(day)
        unless (current_day[keys[i]].nil? && current_day[keys[i + 1]].nil?)
          time_start = current_day[keys[i]].to_s(:time).split(":").map {|s| s.to_i}
          time_end = current_day[keys[i + 1]].to_s(:time).split(":").map {|s| s.to_i}
          if (time_start[1] == 30)
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(current_day.day).month_of_year(months).hour_of_day(time_start[0]).minute_of_hour(30))
            time_start[0] += 1
          end
          if (time_end[1] == 00)
            hours_range = (time_start[0]..(time_end[0] - 1)).to_a
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(current_day.day).month_of_year(months).hour_of_day(hours_range).minute_of_hour(0, 30))
          end
          if (time_end[1] == 59)
            hours_range = (time_start[0]..time_end[0]).to_a
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(current_day.day).month_of_year(months).hour_of_day(hours_range).minute_of_hour(0, 30))
          end
          if (time_end[1] == 30)
            hours_range = (time_start[0]..(time_end[0] - 1)).to_a
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(current_day.day).month_of_year(months).hour_of_day(hours_range).minute_of_hour(0, 30))
            @asset.schedule.add_recurrence_rule(IceCube::Rule.daily.day(current_day.day).month_of_year(months).hour_of_day(time_end[0]).minute_of_hour(0))
          end

        end
      end
    end
    @asset.save
  end

  def set_daily_rule_new(availability)
    year = Year.where(availability_id: availability.id).select("year").map {|v| v[:year]}.first
    month = Month.where(availability_id: availability.id).where(checked: true).select("month").map {|v| v[:month]}.first
    day = Day.where(availability_id: availability.id).where(" am_start IS NOT NULL OR pm_start  IS NOT NULL").ids.first

    keys = ["am_start", "am_end", "pm_start", "pm_end"]
    (0..2).step(2).each do |i|
      current_day = Day.find(day)
      unless (current_day[keys[i]].nil? && current_day[keys[i + 1]].nil?)
        time_start = current_day[keys[i]].to_s(:time).split(":").map {|s| s.to_i}
        time_end = current_day[keys[i + 1]].to_s(:time).split(":").map {|s| s.to_i}
        if (time_start[1] == 30)
          @asset.schedule.add_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(time_start[0]).minute_of_hour(30).day_of_month(current_day.day))
          time_start[0] += 1
        end
        if (time_end[1] == 00)
          hours_range = (time_start[0]..(time_end[0] - 1)).to_a
          @asset.schedule.add_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30).day_of_month(current_day.day))

        end
        if (time_end[1] == 59)
          hours_range = (time_start[0]..time_end[0]).to_a
          @asset.schedule.add_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30).day_of_month(current_day.day))
        end
        if (time_end[1] == 30)
          hours_range = (time_start[0]..(time_end[0] - 1)).to_a
          @asset.schedule.add_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(hours_range).minute_of_hour(0, 30).day_of_month(current_day.day))
          @asset.schedule.add_recurrence_rule(IceCube::Rule.yearly(year).month_of_year(month).hour_of_day(time_end[0]).minute_of_hour(0).day_of_month(current_day.day))
        end
      end
      puts ">>>>>>>>>>>>>>>>>year=" + year.to_s + " month=" + month.to_s + " day=" + current_day.day.to_s + " time_start=" + time_start.to_s + " time_end=" + time_end.to_s
    end
    @asset.save
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_availability
    @availability = Availability.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def availability_params
    params.require(:availability).permit(
      days_attributes: [:day, :am_start, :am_end, :pm_start, :pm_end],
      months_attributes: [:month, :checked],
      years_attributes: [:year]
    )
  end

end
