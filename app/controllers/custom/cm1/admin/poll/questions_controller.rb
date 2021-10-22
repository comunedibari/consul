class Admin::Poll::QuestionsController < Admin::Poll::BaseController
  include CommentableActions

  load_and_authorize_resource :poll
  load_and_authorize_resource :question, class: 'Poll::Question'
  

  def index

    @polls = Poll.by_user_pon
    @search = search_params[:search]
    #@questions = @questions.by_user_pon.where("poll_questions.id = group_id or poll_questions.group_id is null").search(search_params).page(params[:page]).order("created_at DESC")
    @questions = @questions.by_user_pon.where("poll_questions.id = group_id or poll_questions.title = '----'").search(search_params).page(params[:page]).order("created_at DESC")

    @proposals = Proposal.successful.sort_by_confidence_score
  end


  def new       
    @polls = Poll.by_user_pon.order("id")
    if @polls.count == 0
      redirect_to admin_questions_path, alert: t("admin.questions.new.no_polls_error")
    elsif params[:question_id].present?
      #prova a creare una domanda per quesito tabellare
      new_underquestion
    else
      @question = Poll::Question.new

      proposal = Proposal.find(params[:proposal_id]) if params[:proposal_id].present?
      
      @question.copy_attributes_from_proposal(proposal)

      load_data_for_edit      
    end

  end

  def create    
    flag = true
    #se il quesito non è di tipo 3 (opzionale) svuoto i campi per i quesiti opzionali
    if @question.poll_question_type_id != 3
      @question.question_optional_id = nil
      @question.poll_question_answer_id = nil

      #se il quesito è di tipo 2 (tabellare) setto il group_tile con title inserito dall'utente e setto il titolo con "----" per consentire l'inserimento
      if @question.poll_question_type_id == 2
        if !question_params[:group_id].nil?
          flag = false
          save_under_question
        else
          @question.group_title = @question.title
          @question.title = "----" 
        end
      end
    end
    if flag == true
      @question.author = @question.proposal.try(:author) || current_user    
      if @question.save      
        @question.update_attribute(:group_id, @question.id)
        redirect_to admin_question_path(@question), notice: t("flash.actions.create.question")     
      else
        load_data_for_edit
        render :new
      end
    end
  end

  def show
    if @question.poll_question_type_id == 2
      @question.title = @question.group_title
      if params[:filter].present? and ["question_group", "answer_group"].include? params[:filter]
        @current_filter = params[:filter]
      else
        @current_filter = "question_group"
      end
    else
      @current_filter = nil
    end

    if @question && @question.pon_id != current_user.pon_id
      raise CanCan::AccessDenied
    end   

    @questions = Poll::Question.by_user_pon.where.not(title: '----').where(group_id: @question.id).page(params[:page]).order("created_at DESC")

  end

  def edit

    if params[:type].present?
      #prova a creare una domanda per quesito tabellare
      editunderquestion
    else
      @num_min_answers_select_options = (0..1).step(1).to_a.map{|s| ["#{s}", s]} + (2..@question.question_answers.count).step(1).to_a.map{|s| ["#{s}", s]}
      @num_max_answers_select_options = (0..@question.question_answers.count).step(1).to_a.map{|s| ["#{s}", s]}

      @polls = Poll.by_user_pon

      if @question.poll_question_type_id == 3

        ids_q = Poll::Question.where(poll_id: @question.poll_id).order("id").pluck(:id)
        ids_a = Poll::Question::Answer.distinct.select("question_id").where("title != 'Altro'").where(question_id: ids_q).order("question_id").pluck("question_id")
        #@questions = Poll::Question.where(id: ids_a).order("id")
        @questions = Poll::Question.where(group_id: ids_a).where.not(id: @question.id).where.not(title: "----").order("id")
    
        @answers =  Poll::Question::Answer.where(question_id:  @question.question_optional_id).order("id")      

      else              
        if @question.poll_question_type_id == 2
          @question.title = @question.group_title
        end

        @questions = Poll::Question.where(poll_id: @question.poll_id).order("id")
        @answers =  Poll::Question::Answer.where(question_id:  @questions.first.id).order("id")

      end

      @type_questions = @questions.count > 0 ? Poll::QuestionType.all.order("id") : Poll::QuestionType.where(id: [1,2]).order("id")

    end
  end

  def update
    title = @question.title    
    if @question.update(question_params)
      if @question.poll_question_type_id != 3
        @question.question_optional_id = nil
        @question.poll_question_answer_id = nil
        if @question.poll_question_type_id == 2
          @question.group_title = @question.title
          @question.title = title
          if @question.id == @question.group_id or @question.group_id.nil?
            questions = Poll::Question.by_user_pon.where(group_id: @question.id)
            if !questions.nil?
              questions.update_all(num_max_answers: @question.num_max_answers)
              questions.update_all(num_min_answers: @question.num_min_answers)
            end
          end
        end
        @question.save
      end
      redirect_to admin_question_path(@question), notice: t("flash.actions.update.question")
    else

      @num_min_answers_select_options = (0..1).step(1).to_a.map{|s| ["#{s}", s]} + (2..@question.question_answers.count).step(1).to_a.map{|s| ["#{s}", s]}
      @num_max_answers_select_options = (0..@question.question_answers.count).step(1).to_a.map{|s| ["#{s}", s]}
  
      @polls = Poll.by_user_pon

      if @question.poll_question_type_id == 3
  
        ids_q = Poll::Question.where(poll_id: @question.poll_id).order("id").pluck(:id)
        ids_a = Poll::Question::Answer.distinct.select("question_id").where("title != 'Altro'").where(question_id: ids_q).order("question_id").pluck("question_id")
        @questions = Poll::Question.where(id: ids_a).order("id")
    
        @answers =  Poll::Question::Answer.where(question_id:  @question.question_optional_id).order("id")      
  
      else              
  
        @questions = Poll::Question.where(poll_id: @question.poll_id).order("id")
        @answers =  Poll::Question::Answer.where(question_id:  @questions.first.id).order("id")
  
      end
  
      @type_questions = @questions.count > 0 ? Poll::QuestionType.all.order("id") : Poll::QuestionType.where(id: [1,2]).order("id")
  
      render :edit
    end
  end

 
  def destroy
    if @question.poll_question_type_id == 2
      if @question.group_id == @question.id and Poll::Question.where(group_id: @question.group_id).destroy_all()
        #cancella tutti i sotto quesiti e il quesito principale
        notice = t("flash.actions.destroy.question")
      else
        notice = t("flash.actions.destroy.error")
      end
    elsif @question.destroy
      notice = t("flash.actions.destroy.question")
    else
      notice = t("flash.actions.destroy.error")
    end
    redirect_to admin_questions_path, notice: notice
  end

  def editunderquestion

    @question_group = Poll::Question.where(id: @question.group_id).first
    if !@question_group.nil? and @question_group.poll_question_type_id == 2
      render :edit_underquestion
    else
      notice = t("flash.actions.destroy.error")
      redirect_to admin_questions_path, notice: notice
    end

  end

  def update_underquestion
    @question_group = Poll::Question.where(id: @question.group_id).first
    if !@question_group.nil? and @question_group.poll_question_type_id == 2 and !params[:poll_question][:title].nil?
      @question.title = params[:poll_question][:title]
      if @question.save
        notice= t('notice.operaction_successfull')
        redirect_to admin_question_path(@question.group_id), notice: notice               
      else     
        render :edit_underquestion
      end      
    else
      notice = t("flash.actions.destroy.error")
      redirect_to admin_questions_path, notice: notice
    end

  end

  def load_question
    if @question.nil?
      @question = Poll::Question.new
    end

    ids_q = Poll::Question.where(poll_id: params[:poll_id]).order("id").pluck(:id)
    ids_a = Poll::Question::Answer.distinct.select("question_id").where("title != 'Altro'").where(question_id: ids_q).order("question_id").pluck("question_id")
    @questions = Poll::Question.where(id: ids_a).order("id")

    @answers =  Poll::Question::Answer.where(question_id:  @questions.first.id).order("id")
    @type_questions = @questions.count > 0 ? Poll::QuestionType.all.order("id") : Poll::QuestionType.where(id: [1,2]).order("id")
    respond_to do |format|
      format.js
    end
  end

  def load_answer
    if @question.nil?
      @question = Poll::Question.new
    end
    #@answers =  Poll::Question::Answer.where(question_id: params[:question_id]).where.not(title: "Altro")
    ques_ans = Poll::Question.find(params[:question_id])
    @answers =  Poll::Question::Answer.where(question_id: ques_ans.group_id).where.not(title: "Altro")

    respond_to do |format|
      format.js
    end
  end

  def delunderquestion
    group_id = @question.group_id
    if @question.poll_question_type_id == 2 and @question.group_id == @question.id
      @question.title = "----"
      @question.group_id = nil
      if @question.save
        notice = t("flash.actions.destroy.question")
      else
        notice = t("flash.actions.destroy.error")
      end
    elsif @question.poll_question_type_id == 2 and @question.destroy
      notice = t('notice.operaction_successfull')
    else
      notice = t("flash.actions.destroy.error")
    end
    redirect_to admin_question_path(group_id), notice: notice
  end
  

  private

    def question_params
      params.require(:poll_question).permit(:poll_id, :title, :question,:proposal_id, :video_url, :num_max_answers, :num_min_answers,
                                            :poll_question_type_id,:question_optional_id, :poll_question_answer_id,
                                            :group_id, :group_title,
                                            images_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy],
                                            documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy]
                                            )
    end

    def search_params
      params.permit(:poll_id, :search)
    end

    def new_underquestion
      question_id = params[:question_id]
      @question_group = Poll::Question.where(id: question_id).first
      if @question_group.nil?
        notice = t("admin.questions.new.error")
        redirect_to admin_questions_path, alert: notice        
      else        
        @question = Poll::Question.new
        @question.group_id = question_id
        @question.poll_id = @question_group.poll_id
        @question.poll_question_type_id = 2
        @question.group_title = @question_group.group_title
        render :underquestion
      end
    end

    def save_under_question
      question_id = question_params[:group_id]
      @question_group = Poll::Question.where(id: question_id).first
      if @question_group.nil?
        notice = t("admin.questions.new.error")
        redirect_to admin_questions_path, alert: notice        
      else        
        @question.num_max_answers = @question_group.num_max_answers
        @question.num_min_answers = @question_group.num_min_answers
        @question.author = @question.proposal.try(:author) || current_user    
        @question.group_title = nil
        if @question.save      
          redirect_to admin_question_path(@question_group)      
        else
          render :underquestion
        end  

      end
    end

    def load_data_for_edit
      @num_max_answers_select_options = {}
      @num_max_answers_select_options.store("0", "0")
      @num_min_answers_select_options = {}
      @num_min_answers_select_options.store("0", "0")
      @num_min_answers_select_options.store("1", "1")

      @polls = Poll.by_user_pon.order("id")
      if @polls.count > 0

        ids_q = Poll::Question.where(poll_id: @polls.first.id).order("id").pluck(:id)
        ids_a = Poll::Question::Answer.distinct.select("question_id").where("title != 'Altro'").where(question_id: ids_q).order("question_id").pluck("question_id")
        #@questions = Poll::Question.where(id: ids_a).order("id")
        
        #@questions = Poll::Question.where(id: ids_a).where.not(title: "----").order("id")
        @questions = Poll::Question.where(group_id: ids_a).where.not(title: "----").order("id")

        @type_questions = @questions.count > 0 ? Poll::QuestionType.all.order("id") : Poll::QuestionType.where(id: [1,2]).order("id")
        
        #@answers = @questions.count == 0 ? Poll::Question::Answer.where(question_id:  0) : Poll::Question::Answer.where(question_id:  @questions.first.id).where("title != 'Altro'").order("id")
        @answers = @questions.count == 0 ? Poll::Question::Answer.where(question_id:  0) : Poll::Question::Answer.where(question_id:  @questions.first.group_id).where("title != 'Altro'").order("id")
      else
        @questions = Poll::Question.where(poll_id: 0)
        @type_questions = Poll::QuestionType.where(id: [1,2])
        @answers =  Poll::Question::Answer.where(id:  0)
      end
    end

end
