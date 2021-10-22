module Flaggable
  extend ActiveSupport::Concern

  included do
    has_many :flags, as: :flaggable
    scope :flagged, -> {where("flags_count > 0")}
    scope :all_moderate, -> { where("moderation_entity in (1,3) or (flags_count > 0 and ignored_flag_at is null)")}
    scope :new_hidden, -> {mod_pending_moderator}
    scope :pending_flag_review, -> {flagged.where(ignored_flag_at: nil, hidden_at: nil,moderation_entity: 1)}
    scope :with_ignored_flag, -> {flagged.where.not(ignored_flag_at: nil).where(hidden_at: nil)}
    scope :new_adds, -> {StSector.where(state: 1)}
    scope :change_requests, -> {StSector.where(state: 5)}
    scope :cancellation_requests, -> {StSector.where(state: 8)}
  end

  def ignored_flag?
    ignored_flag_at.present?
  end

  def ignore_flag
    if flags_count > 0
      update(ignored_flag_at: Time.current)
    end
  end

end
