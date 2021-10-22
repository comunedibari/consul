class Availability < ActiveRecord::Base

  belongs_to :asset
  has_many :days, :dependent => :destroy
  has_many :months, :dependent => :destroy
  has_many :years, :dependent => :destroy

  accepts_nested_attributes_for :days
  accepts_nested_attributes_for :months
  accepts_nested_attributes_for :years


  validate :validate_months
  validate :validate_days
  validate :validate_single_day


  scope :weekly, -> {includes(:years).where(years: { availability_id: nil })}
  scope :daily, -> {joins(:years)}


  def validate_months
    valid = false

    months.each do |month|
      if month.checked
        valid = true
      end
    end
    unless valid
      errors.add(:months, I18n.t('verification.availability.new.errors.at_least_a_month'))
    end
  end

  def validate_days
    valid = 0

    days.each do |day|
      if day.am_start.nil? && day.am_end.nil? && day.pm_start.nil? && day.pm_end.nil?
        valid += 1
      end
    end
    if valid == 7
      errors.add(:days, I18n.t('verification.availability.new.errors.in_hours'))
    end
  end

  def validate_single_day
    days.each do |day|
      if (day.am_start.nil? && day.am_end.nil? && day.pm_start.nil? && day.pm_end.nil?) && (days.size == 1)
        errors.add(:days, I18n.t('verification.availability.new.errors.in_hours'))
      end
    end
  end
end
