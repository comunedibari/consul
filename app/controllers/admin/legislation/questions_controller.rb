class Admin::Legislation::QuestionsController < Admin::Legislation::BaseController
  load_and_authorize_resource :process, class: "::Legislation::Process"
  load_and_authorize_resource :question, class: "::Legislation::Question", through: :process

  def index
    @questions = @process.questions
  end

  def new
    @question.question_options.build
  end

  def create
    @question.author = @process.author
    if @question.save
      set_in_moderation

      if current_user.administrator? || current_user.moderator?
        notice = t('admin.legislation.questions.create.notice', link: question_path)
        redirect_to admin_legislation_process_questions_path, notice: notice
      else 
        notice = t('admin.legislation.questions.create.notice_user', link: question_path)
        redirect_to admin_legislation_process_questions_path, notice: notice
      end
    else
      flash.now[:error] = t('admin.legislation.questions.create.error')
      render :new
    end
  end

  def update
    if @question.update(question_params)
      set_in_moderation
      if current_user.administrator? || current_user.moderator?
        notice = t('admin.legislation.questions.update.notice', link: question_path)
        redirect_to edit_admin_legislation_process_question_path(@process, @question), notice: notice
      else 
        notice = t('admin.legislation.questions.update.notice_user', link: question_path)
        redirect_to edit_admin_legislation_process_question_path(@process, @question), notice: notice
      end
    else
      flash.now[:error] = t('admin.legislation.questions.update.error')
      render :edit
    end
  end

  def destroy
    if @question.comments.count > 0 
      notice = t('admin.legislation.questions.destroy.error_exists_comment')
      redirect_to :back, alert: notice 
    else
      @question.destroy
      notice = t('admin.legislation.questions.destroy.notice')
      redirect_to admin_legislation_process_questions_path, notice: notice
    end
  end

  private

    def question_path
      legislation_process_question_path(@process, @question).html_safe
    end

    def question_params
      params.require(:legislation_question).permit(
        :title,
        question_options_attributes: [:id, :value, :_destroy]
      )
    end
end
