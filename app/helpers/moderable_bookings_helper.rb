module ModerableBookingsHelper

 def admin_moderable_booking_submit_action(moderable_booking)
  moderable_booking.persisted? ? "approve" : "disapprove"
 end

 def booking_select_options(include_all = nil)
  #options = @moderable_bookings.collect do |moderable_booking|
  #  [Asset.find(moderable_booking.bookable_id).name, current_path_with_query_params(bookable_id: moderable_booking.bookable_id)]
  #end
  assets = Asset.by_user_pon
  options = assets.collect do |asset|
    [asset.name, current_path_with_query_params(bookable_id: asset.id)]
  end
  options << all_moderable_bookings if include_all
  options_for_select(options, request.fullpath)
end

def all_moderable_bookings
  [I18n.t("admin.moderable_bookings.all"), current_path_with_query_params(bookable_id: Asset.by_user_pon.pluck(:id))]
end

def retire_moderable_bookings_options
  BookingManager::ModerableBooking::RETIRE_OPTIONS.collect { |option| [ t("proposals.retire_options.#{option}"), option ] }
end
 
=begin
  
  
end
  def author_of( moderable_booking)
    author_name = User.all.where(id: moderable_booking.author_id).first.username
  end


  def time_missing(moderable_booking)
    if moderable_booking.end_date? && moderable_booking.start_date?
      days_missing = (moderable_booking.end_date.to_date - Time.current.beginning_of_day.to_date).to_i
    end
  end

  def percentage_achieved(moderable_booking)
    if (moderable_booking.total_investiment != nil) && (moderable_booking.price_goal != nil)
      (moderable_booking.total_investiment / moderable_booking.price_goal) * 100
    end
  end


  def namespaced_moderable_booking_path(moderable_booking, options = {})
    @namespace_moderable_booking_path ||= namespace
    case @namespace_moderable_booking_path
    when "management"
      management_moderable_booking_path(moderable_booking, options)
    else
      moderable_booking_path(moderable_booking, options)
    end
  end

  def retire_moderable_bookings_options
    BookingManager::ModerableBooking::RETIRE_OPTIONS.collect { |option| [ t("moderable_bookings.retire_options.#{option}"), option ] }
  end

  def empty_recommended_moderable_bookings_message_text(user)
    if user.interests.any?
      t('moderable_bookings.index.recommendations.without_results')
    else
      t('moderable_bookings.index.recommendations.without_interests')
    end
  end

  def author_of_moderable_booking?(moderable_booking)
    author_of?(moderable_booking, current_user)
  end

  def current_editable?(moderable_booking)
    current_user && moderable_booking.editable_by?(current_user)
  end

  def current_moderable_comments?(moderable_booking)
    current_user && moderable_booking.moderable_comments_by?(current_user)
  end


  def moderable_bookings_minimal_view_path
    moderable_bookings_path(view: moderable_bookings_secondary_view)
  end

  def moderable_bookings_default_view?
    @view == "default"
  end

  def moderable_bookings_current_view
    @view
  end

  def moderable_bookings_secondary_view
    moderable_bookings_current_view == "default" ? "minimal" : "default"
  end


  def status(moderable_booking)
    if moderable_booking.open? && (moderable_booking.not_retired?) 
      t("admin.moderable_bookings_admin.moderable_booking.status_open")
    elsif moderable_booking.next? && (moderable_booking.not_retired?)
      t("admin.moderable_bookings_admin.moderable_booking.status_planned")
    elsif moderable_booking.past? || moderable_booking.retired?  
      t("admin.moderable_bookings_admin.moderable_booking.status_closed")
    end
  end

=end  
end
