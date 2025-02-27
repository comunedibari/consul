class Admin::BannersController < Admin::BaseController

  has_filters %w{all with_active with_inactive}, only: :index

  before_action :banner_styles, only: [:edit, :new, :create, :update]
  before_action :banner_imgs, only: [:edit, :new, :create, :update]

  respond_to :html, :js

  load_and_authorize_resource

  def index
    @banners = Banner.send(@current_filter).by_user_pon.page(params[:page])
  end

  def create
    @banner = Banner.new(banner_params)
    if @banner.save
      redirect_to admin_banners_path
    else
      render :new
    end
  end

  def update
    if @banner.update(banner_params)
      redirect_to admin_banners_path
    else
      render :edit
    end
  end

  def destroy
    @banner.destroy
    redirect_to admin_banners_path
  end

  private

    def banner_params
      attributes = [:title, :description, :target_url, :style, :image,
                    :post_started_at, :post_ended_at]
      params.require(:banner).permit(*attributes)
    end

    def banner_styles
      @banner_styles = Setting.by_user_pon.banner_style.map do |banner_style|
                         [banner_style.value, banner_style.key.split('.')[1]]
                       end
    end

    def banner_imgs
      @banner_imgs = Setting.by_user_pon.banner_img.map do |banner_img|
                       [banner_img.value, banner_img.key.split('.')[1]]
                     end
    end

end
