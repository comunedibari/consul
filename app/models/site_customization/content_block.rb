class SiteCustomization::ContentBlock < ActiveRecord::Base
  VALID_BLOCKS = %w(top_links footer)

  validates :locale, presence: true, inclusion: { in: I18n.available_locales.map(&:to_s) }


  belongs_to :pon
  scope :by_user_pon,              -> { where(pon_id: User.pon_id)}

  def self.block_for(name, locale)
    locale ||= I18n.default_locale
    find_by(name: name, locale: locale, pon_id: User.pon_id).try(:body)
  end
end
