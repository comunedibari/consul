class Day < ActiveRecord::Base

  belongs_to :availability

  validate :valid_date?



  def valid_date?
    errors.add(:pm_start, :invalid) if !pm_start.blank? && pm_end.blank?
    errors.add(:am_start, :invalid) if !am_start.blank? && am_end.blank?
  end
end



