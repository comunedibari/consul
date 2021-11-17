class Admin::Poll::Questions::AnswersController < Admin::Poll::BaseController
  before_action :load_answer, only: [:show, :edit, :update, :documents]


  load_and_authorize_resource :question, class: "::Poll::Question"
  load_and_authorize_resource :answer, class: '::Poll::Question::Answer'

  before_action :check_question_permission

  def check_question_permission
    if @question && @question.pon_id != current_user.pon_id
      raise CanCan::AccessDenied
    end
  end


  def new
    #rafforziamo il controllo per i casi di group_id = null, forzando un setting sull'attributo
    if @question.group_id.nil? and @question.poll_question_type_id == 2 and @question.title == "----"
      fix_group_id
    end

    #controllo che la domanda tabellare non abbia gia 10 risposte inserite
    if @question.poll_question_type_id == 2 && @question.question_group.question_answers.count == 10
      redirect_to admin_question_path(@question), alert: t("admin.answers.new.error_max")     
    else
      @answer = ::Poll::Question::Answer.new
    end
  end

  def create
    @answer = ::Poll::Question::Answer.new(answer_params)

    if @answer.save
      #verifico se trattandosi della prima risposta inserita e il num_max_answers è ancora settato a 0, le reimposto ad 1
      if @question.question_group.num_max_answers == 0
        Poll::Question.where(group_id: @question.group_id).update_all(num_max_answers: 1)
      end
      redirect_to admin_question_path(@answer.question),
                  notice: t("flash.actions.create.poll_question_answer")
    else
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @answer.update(answer_params)
      redirect_to admin_question_path(@answer.question),
                  notice: t("flash.actions.save_changes.notice")
    else
      redirect_to :back
    end
  end

  def documents
    @documents = @answer.documents

    render 'admin/poll/questions/answers/documents'
  end

  def order_answers
    ::Poll::Question::Answer.order_answers(params[:ordered_list])
    render nothing: true
  end

  def destroy
    if  @answer.question.question_answers.count - 1 < @answer.question.num_max_answers
      @answer.question.num_max_answers = @answer.question.question_answers.count - 1
      @answer.question.save
    end
    ::Poll::Question::Answer.destroy(params[:id])
    redirect_to :back, notice: t("flash.actions.destroy.poll_question_answer")

  end

  private

  def answer_params
    documents_attributes = [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy]
    attributes = [:title, :description, :question_id, documents_attributes: documents_attributes]
    params.require(:poll_question_answer).permit(*attributes)
  end

  def load_answer
    @answer = ::Poll::Question::Answer.find(params[:id] || params[:answer_id])
  end

  def fix_group_id
    @question.update_attribute(:group_id, @question.id)
  end

end
