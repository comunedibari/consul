class Admin::TagsController < Admin::BaseController
  before_action :find_tag, only: [:update, :destroy]

  respond_to :html, :js


  def index
    @tags = ActsAsTaggableOn::Tag.category.page(params[:page])
    @tag  = ActsAsTaggableOn::Tag.category.new
  end

  def create
    #logger.debug "----prova-----------------------------------------------------------------------"

    @tag = ActsAsTaggableOn::Tag.category.new(tag_params)

    # if isEquals 
    #   redirect_to admin_tags_path, flash: { error: t('admin.tags.error.duplicate') } and return
    # end

    if @tag.valid?
      logger.debug "valid: SI**************************************************************************************************************************"
    else
      logger.debug "valid: NO********************************************************************************************************************************"
    end  


    if @tag.save
      redirect_to admin_tags_path, notice: t("admin.tags.afterCreation")
    else
      if isEquals
        redirect_to admin_tags_path, flash: { error: t('admin.tags.error.duplicate') }
      else
        redirect_to admin_tags_path, flash: { error: t('admin.tags.error.insert') }
      end
    end  
        
  end


 def isEquals
  @query = ActsAsTaggableOn::Tag.where( name: @tag.name ).count
      #logger.debug "Q U E R Y !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      #logger.debug @query
      if @query != 0
        return true
      else
        return false
      end
 end



  def destroy
    UserTag.where(tag: @tag).delete_all
    @tag.destroy
    redirect_to admin_tags_path, notice: t("admin.tags.destroyed") 
  end

  private

    def tag_params
      params.require(:tag).permit(:name, :pon_id)
    end

    def find_tag
      @tag = ActsAsTaggableOn::Tag.category.find(params[:id])
    end

end
