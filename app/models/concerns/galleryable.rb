module Galleryable
  extend ActiveSupport::Concern

  included do
    has_many :images, as: :imageable, dependent: :destroy
    accepts_nested_attributes_for :images, allow_destroy: true, update_only: true

    def image_url(style)
      _image = images.first
      _image.attachment.url(style) if _image && _image.attachment.exists?
    end
  end
end