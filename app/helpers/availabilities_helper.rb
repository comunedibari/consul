module AvailabilitiesHelper
  def show_all_availabilities_for_asset(asset)
    Availability.where(asset_id: asset)
  end

  def get_month_by_number (num)
    months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio',
      'Giugno', 'Luglio', 'Agosto', 'Settembre',
      'Ottobre', 'Novembre', 'Dicembre']
    months[num]
  end

  def get_months_by_numbers(nums)
    ls = ""
    nums.each do |num|
      ls = ls + get_month_by_number(num-1)+","
    end
    ls[0...-1]
  end

  def get_day_by_number (num)
    days = [
      'Domenica', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato'
    ]
    days[num]
  end



end

