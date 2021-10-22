class UserTagsController < ApplicationController

  load_and_authorize_resource

  def index

  end


  def new
    user_tag = UserTag.new(user: current_user, tag_id: params[:tag_id])
    user_tag.save
    redirect_to preferences_account_path, notice: t("admin.settings.flash.updated")
  end


  def destroy
    UserTag.destroy(params[:id])
    redirect_to preferences_account_path, notice: "OK, operazione eseguita correttamente"
  end

  private

    def user_tags_params

    end

end