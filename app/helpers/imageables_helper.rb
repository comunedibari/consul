module ImageablesHelper

  def can_destroy_image?(imageable)
    imageable.images.present? && can?(:destroy, imageable.images.first)
  end

  def imageable_class(imageable)
    imageable.class.name.parameterize('_')
  end

  def max_images_allowed(imageable)
    imageable.class.max_images_allowed
  end

  def imageable_max_file_size
    bytes_to_megabytes(Image::MAX_IMAGE_SIZE)
  end

  def bytes_to_megabytes(bytes)
    bytes / Numeric::MEGABYTE
  end

  def imageable_accepted_content_types
    Image::ACCEPTED_CONTENT_TYPE
  end

  def imageable_accepted_content_types_extensions
    Image::ACCEPTED_CONTENT_TYPE
      .collect{ |content_type| ".#{content_type.split('/').last}" }
      .join(",")
  end

  def imageable_humanized_accepted_content_types
    Image::ACCEPTED_CONTENT_TYPE
      .collect{ |content_type| content_type.split("/").last }
      .join(", ")
  end

  def imageables_note(imageable,max_i=nil)
    if ( max_i.nil? )
      max_i=max_images_allowed(imageable)
    end
    t "images.form.note", max_images_allowed: max_i,
                          accepted_content_types: imageable_humanized_accepted_content_types,
                          max_file_size: imageable_max_file_size
  end

  def max_images_allowed?(imageable)
    imageable.images.count >= imageable.class.max_images_allowed
  end

end
