module Imageable
  extend ActiveSupport::Concern

  included do
    has_many :images, as: :imageable, dependent: :destroy
    accepts_nested_attributes_for :images, allow_destroy: true

    def image_url(style)
     _image = images.first
     _image.attachment.url(style) if _image && _image.attachment.exists?
    end

  end  

  module ClassMethods
    attr_reader :max_images_allowed

    private

    def imageable(options = {})
      @max_images_allowed = options[:max_images_allowed]
    end
  end
  
end


