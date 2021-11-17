class Admin::Collaboration::AgreementRequirementsController <  Admin::Collaboration::BaseController
  load_and_authorize_resource :collaboration_agreement, class: "::Collaboration::Agreement"
  load_and_authorize_resource :agreement_requirement, class: "::Collaboration::AgreementRequirement", through: :agreement

  def index
    @agreement_requirements = @agreement.agreement_requirements
  end

  def new
    @agreement_requirement.question_options.build
  end

  def create
    #@agreement_requirement.author = @agreement.author
    if @agreement_requirement.save
      set_in_moderation

      if current_user.administrator? || current_user.moderator?
        notice = t('admin.collaboration.agreement_requirements.create.notice')
        redirect_to admin_collaboration_agreement_agreement_requirements_path, notice: notice
      #else 
      #  notice = t('admin.legislation.questions.create.notice_user', link: agreement_requirement_path)
      #  redirect_to admin_collaboration_agreement_agreement_requirements_path, notice: notice
      end
    else
      flash.now[:error] = t('admin.collaboration.agreement_requirements.create.error')
      render :new
    end
  end

  def update
    if @agreement_requirement.update(agreement_requirement_params)
      set_in_moderation
      if current_user.administrator? || current_user.moderator?
        notice = t('admin.collaboration.agreement_requirements.update.notice')
        redirect_to admin_collaboration_agreement_agreement_requirements_path, notice: notice
      #else 
      #  notice = t('admin.legislation.questions.update.notice_user', link: agreement_requirement_path)
      #  redirect_to edit_admin_collaboration_agreement_agreement_requirement_path(@agreement, @agreement_requirement), notice: notice
      end
    else
      flash.now[:error] = t('admin.collaboration.agreement_requirements.update.error')
      render :edit
    end
  end

  def destroy
    #if @agreement_requirement.comments.count > 0 
    #  notice = t('admin.legislation.questions.destroy.error_exists_comment')
    #  redirect_to :back, alert: notice 
    #else
      @agreement_requirement.destroy
      notice = t('admin.collaboration.agreement_requirements.destroy.notice')
      redirect_to admin_collaboration_agreement_agreement_requirements_path, notice: notice
    #end
  end

  private

    def agreement_requirement_path
      admin_collaboration_agreement_agreement_requirement_path(@agreement, @agreement_requirement).html_safe
    end

    def agreement_requirement_params
      params.require(:collaboration_agreement_requirement).permit(
        :title, :collaboration_agreement_id,
        collaboration_agreement_attributes: [:collaboration_agreement_id],
        question_options_attributes: [:id, :value, :_destroy]
      )
    end

end
