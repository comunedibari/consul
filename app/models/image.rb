class Image < ActiveRecord::Base
  include ImagesHelper
  include ImageablesHelper


  TITLE_LEGHT_RANGE = 4..500
  MIN_SIZE = 475

  SH_MIN_SIZE_H = 99
  SH_MIN_SIZE_W = 1800
  LG_MIN_SIZE = 150

  MAX_IMAGE_SIZE = 5.megabyte
  ACCEPTED_CONTENT_TYPE = Rails.application.config.images_content_types.freeze #%w(image/jpeg image/jpg image/png).freeze

  has_attached_file :attachment,
                    styles: {large: "x#{MIN_SIZE}", medium: "300x300#", thumb: "140x245#"},
                    whiny: false,
                    url: "/system/:class/:prefix/:style/:hash.:extension",
                    hash_data: ":class/:style/:custom_hash_data",
                    use_timestamp: false,
                    hash_secret: Rails.application.secrets.secret_key_base

  attr_accessor :cached_attachment, :remove, :original_filename

  belongs_to :user
  belongs_to :imageable, polymorphic: true

  # Disable paperclip security validation due to polymorphic configuration
  # Paperclip do not allow to use Procs on valiations definition
  do_not_validate_attachment_file_type :attachment

  validate :attachment_presence
  #validate :validate_attribute_image #, if: -> {attachment.present?}
  validate :validate_attachment_content_type, if: -> {attachment.present?}
  validate :validate_attachment_size, if: -> {attachment.present?}
  validates :title, presence: true, length: {in: TITLE_LEGHT_RANGE}, if: -> {attachment.present?}
  validates :user_id, presence: true
  validates :imageable_id, presence: true, if: -> {persisted?}
  validates :imageable_type, presence: true, if: -> {persisted?}
  validate :validate_image_dimensions, if: -> {attachment.present? && attachment.dirty?}

  before_save :set_attachment_from_cached_attachment, if: -> {cached_attachment.present?}
  after_save :remove_cached_attachment, if: -> {cached_attachment.present?}

  def set_cached_attachment_from_attachment
    self.cached_attachment = if Paperclip::Attachment.default_options[:storage] == :filesystem
                               attachment.path
                             else
                               attachment.url
                             end
  end

  def set_attachment_from_cached_attachment
    self.attachment = if Paperclip::Attachment.default_options[:storage] == :filesystem
                        File.open(cached_attachment)
                      else
                        URI.parse(cached_attachment)
                      end
  end

  Paperclip.interpolates :prefix do |attachment, style|
    attachment.instance.prefix(attachment, style)
  end

  Paperclip.interpolates :custom_hash_data do |attachment, _style|
    attachment.instance.custom_hash_data(attachment)
  end

  def prefix(attachment, _style)
    if !attachment.instance.persisted?
      "cached_attachments/user/#{attachment.instance.user_id}"
    else
      ":attachment/:id_partition"
    end
  end

  def custom_hash_data(attachment)
    original_filename = if !attachment.instance.persisted? && attachment.instance.remove
                          # puts "**************1 "+ attachment.instance.original_filename
                          attachment.instance.original_filename

                        elsif !attachment.instance.persisted?
                          # puts "**************2 "+ attachment.instance.attachment_file_name
                          attachment.instance.attachment_file_name
                        else
                          # puts "**************3 "+ attachment.instance.title
                          attachment.instance.title
                        end
    # puts "**************4 "+ "83/#{original_filename}"
    "83/#{original_filename}"
  end

  def humanized_content_type
    #attachment_content_type.split("/").last.upcase
    attachment_file_name.split(".").last.upcase
  end

  def get_refer_to
    #COMMENTABLE_TYPES = %w(Debate Proposal Budget::Investment Poll Topic Legislation::Question
    #Legislation::Annotation Legislation::Proposal).freeze
    url = ''
    if self.imageable_type == 'Comment'
      comment = Comment.find(imageable_id)
      if comment.commentable_type == 'Debate'
        url = "/debates/#{comment.commentable_id}"
      end
      if comment.commentable_type == 'Proposal'
        url = "/proposals/#{comment.commentable_id}"
      end
      if comment.commentable_type == 'Crowdfunding'
        url = "/crowdfundings/#{comment.commentable_id}"
      end
      #mia
      if comment.commentable_type == 'Report'
        url = "/reportings/#{comment.commentable_id}"
      end
      if comment.commentable_type == 'Poll'
        url = "/polls/#{comment.commentable_id}"
      end
      if comment.commentable_type == 'Collaboration::Agreement'
        url = "/collaboration/agreements/#{comment.commentable_id}"
      end
    end
    url
  end

  private

  def imageable_class
    imageable_type.constantize if imageable_type.present?
  end

  def validate_image_dimensions

    if attachment_of_valid_content_type?
      dimensions = Paperclip::Geometry.from_file(attachment.queued_for_write[:original].path)
      if (imageable_class.to_s == "Legislation::Process" and !self.imageable.nil?  and self.imageable.process_type.to_s == "5") or (imageable_class.to_s == "Reporting")
        logger.debug "------- Validate passed"
      elsif (imageable_class.to_s == "Setting" && self.imageable.key == "sub_header.image")
        errors.add(:attachment, :min_image_width, required_min_width: SH_MIN_SIZE_W) if dimensions.width < SH_MIN_SIZE_W
        errors.add(:attachment, :min_image_height, required_min_height: SH_MIN_SIZE_H) if dimensions.height < SH_MIN_SIZE_H
      elsif (imageable_class.to_s == "Setting" && self.imageable.key == "ente_logo.image")
        errors.add(:attachment, :min_image_width, required_min_width: LG_MIN_SIZE) if dimensions.width < LG_MIN_SIZE
        errors.add(:attachment, :min_image_height, required_min_height: LG_MIN_SIZE) if dimensions.height < LG_MIN_SIZE
      else
        errors.add(:attachment, :min_image_width, required_min_width: MIN_SIZE) if dimensions.width < MIN_SIZE
        errors.add(:attachment, :min_image_height, required_min_height: MIN_SIZE) if dimensions.height < MIN_SIZE
      end
    end
  end

  def validate_attachment_size
    if imageable_class &&
      attachment_file_size > 5.megabytes
      errors[:attachment] = I18n.t("images.errors.messages.in_between",
                                   min: "0 Bytes",
                                   max: "#{imageable_max_file_size} MB")
    end
  end

  def validate_attachment_content_type
    if imageable_class && !attachment_of_valid_content_type?
      errors[:attachment] = I18n.t("images.errors.messages.wrong_content_type",
                                   content_type: attachment_content_type,
                                   accepted_content_types: imageable_humanized_accepted_content_types)
    end
  end

  def attachment_presence
    if attachment.blank? && cached_attachment.blank?
      errors[:attachment] = I18n.t("errors.messages.blank")
    end
  end

  def attachment_of_valid_content_type?
    attachment.present? && imageable_accepted_content_types.include?(attachment_content_type)
  end

  def remove_cached_attachment
    image = Image.new(imageable: imageable,
                      cached_attachment: cached_attachment,
                      user: user)
    image.set_attachment_from_cached_attachment
    image.attachment.destroy
  end

end
