class Setting < ActiveRecord::Base
  
  include Graphqlable
  
  include Imageable

  imageable max_images_allowed: 1

  validates :key, presence: true
  
  default_scope {order(id: :asc) }
  scope :enabled, -> {where(editable: true).order(id: :asc) }
  scope :banner_style, -> { where("key ilike ?", "banner-style.%")}
  scope :banner_img, -> { where("key ilike ?", "banner-img.%")}
  scope :pon,  -> (pon_id) { where('pon_id' => pon_id)}
  scope :by_user_pon,              -> { where(pon_id: User.pon_id)}
  scope :public_for_api,           -> { all }
  
  def type
    if service_flag?
      'service'
    elsif moderation_flag?
      'moderation'
    elsif service_description_flag?
      'service_description'
    elsif service_social_flag?
      'service_social'
    elsif feature_flag?
      'feature'
    elsif banner_style?
      'banner-style'
    elsif banner_img?
      'banner-img'
    elsif job_flag?
      'job'
    elsif ente_logo_flag?
      'ente_logo'      
    elsif sub_header_flag?
      'sub_header'
    elsif crowdfunding_flag?
      'crowdfunding'      
    else
      'common'
    end
  end

  def feature_flag?
    key.start_with?('feature.')
  end

  def enabled?
    feature_flag? && value.present?
  end

  def service_flag?
    key.start_with?('service.')
  end

  def service_description_flag?
    key.start_with?('service_description')
  end
  
  def service_social_flag?
    key.start_with?('service_social')
  end

  def moderation_flag?
    key.start_with?('moderation.')
  end

  def enabled_moderation_flag?
    moderation_flag? && value.present?
  end

  def enabled_service_social?
    service_social_flag? && value.present?
  end

  def enabled_service?
    service_flag? && value.present?
  end

  def job_flag?
    key.start_with?('job.')
  end
  def enabled_job?
    job_flag? && value.present?
  end

  def ente_logo_flag?
    key.start_with?('ente_logo.')
  end

  def sub_header_flag?
    key.start_with?('sub_header.')
  end

  def crowdfunding_flag?
    key.start_with?('crowdfunding.')
  end


  def banner_style?
    key.start_with?('banner-style.')
  end

  def banner_img?
    key.start_with?('banner-img.')
  end

  class << self
    
    def [](key,pon_id=nil)
      if ( pon_id.nil? )
        #raise "E' obbligatorio il pon_id"
        nil
      else
        pon(pon_id).where(key: key).pluck(:value).first.presence  
      end  
    end

    def []=(key, pon_id, value)
      if ( pon_id.nil? )
        raise "E' obbligatorio il pon_id"
      end 
      setting = where(key: key).where(pon_id: pon_id).first || new(key: key)
      setting.value = value.presence
      setting.save!
      value
    end
  end
end
