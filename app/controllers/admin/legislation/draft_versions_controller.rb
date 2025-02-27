class Admin::Legislation::DraftVersionsController < Admin::Legislation::BaseController
  load_and_authorize_resource :process, class: "Legislation::Process"
  load_and_authorize_resource :draft_version, class: "Legislation::DraftVersion", through: :process

  def index
    @draft_versions = @process.draft_versions
  end

  def create
    if @draft_version.save
      set_in_moderation

      if current_user.administrator? || current_user.moderator?
        link = legislation_process_draft_version_path(@process, @draft_version).html_safe
        notice = t('admin.legislation.draft_versions.create.notice', link: link)
        redirect_to admin_legislation_process_draft_versions_path, notice: notice
      else 
        link = legislation_process_draft_version_path(@process, @draft_version).html_safe
        notice = t('admin.legislation.draft_versions.create.notice_user', link: link)
        redirect_to admin_legislation_process_draft_versions_path, notice: notice
      end
    else
      flash.now[:error] = t('admin.legislation.draft_versions.create.error')
      render :new
    end
  end

  def update
    if @draft_version.update(draft_version_params)
      set_in_moderation
      if current_user.administrator? || current_user.moderator?
        link = legislation_process_draft_version_path(@process, @draft_version).html_safe
        notice = t('admin.legislation.draft_versions.update.notice', link: link)
        edit_path = edit_admin_legislation_process_draft_version_path(@process, @draft_version)
        redirect_to edit_path, notice: notice
      else
        link = legislation_process_draft_version_path(@process, @draft_version).html_safe
        notice = t('admin.legislation.draft_versions.update.notice_user', link: link)
        edit_path = edit_admin_legislation_process_draft_version_path(@process, @draft_version)
        redirect_to edit_path, notice: notice
      end
    else
      flash.now[:error] = t('admin.legislation.draft_versions.update.error')
      render :edit
    end
  end

  def destroy
    @draft_version.destroy
    notice = t('admin.legislation.draft_versions.destroy.notice')
    redirect_to admin_legislation_process_draft_versions_path, notice: notice
  end




  private

    def draft_version_params
      params.require(:legislation_draft_version).permit(
        :title,
        :changelog,
        :status,
        :final_version,
        :body,
        :body_html
      )
    end
end
