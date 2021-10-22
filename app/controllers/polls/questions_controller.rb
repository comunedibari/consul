class Polls::QuestionsController < ApplicationController



  load_and_authorize_resource :poll
  load_and_authorize_resource :question, class: 'Poll::Question'
  respond_to :html, :js
  before_action :load_data, only: :answer

  has_orders %w{most_voted newest oldest}, only: :show

  def answer
    if Poll::Answer.where(author: current_user,question_id:@question.id, answer: params[:answer]).any? and params[:answer] != 'Altro'
      Poll::Answer.where(author: current_user,question_id:@question.id, answer: params[:answer]).delete_all
      @answers_by_question_id[@question.id].delete(params[:answer])

    else
      flag = true
      if @poll_answers.count >= @question.num_max_answers &&  @question.num_max_answers > 1
        if params[:answer] == 'Altro'
          if @poll_answers.where(answer: "Altro").count < 1
            #render :new
            flag = false
          else
            flag = true
          end
        else
          #render :new
          flag = false
        end
      end
      if !flag 
        render :new
      else
        if @poll_answers.count == 1 and @question.num_max_answers == 1
          @poll_answers.first.destroy
        end

        if params[:answer] == 'Altro' && @poll_answers.where(answer: "Altro").count > 0
          @poll_answers.where(answer: "Altro").first.destroy
        end

        if params[:answer] != 'Altro' || params[:content] != ""
          answer = @question.answers.new(author: current_user)
          token = params[:token]
          answer.answer = params[:answer]
          answer.content = params[:content]
          answer.touch if answer.persisted?
          answer.save!
          answer.record_voter_participation(token)
          @question.question_answers.where(question_id: @question).each do |question_answer|
            question_answer.set_most_voted
          end

          if @question.num_max_answers == 1 || !@answers_by_question_id || !@answers_by_question_id[@question.id]
            @answers_by_question_id[@question.id] = Hash.new
          end
          @answers_by_question_id[@question.id][answer.answer] = answer.answer       
        else
          if @question.num_max_answers == 1
            @answers_by_question_id[@question.id] = Hash.new
          end
        end
      end
    end
  end


  def load_data
    @answers_by_question_id = {}
    @poll_answers = ::Poll::Answer.by_question(@question.id).by_author(current_user.try(:id))

    @poll_answers.each do |answer|
      unless @answers_by_question_id[answer.question_id]
        @answers_by_question_id[answer.question_id] = Hash.new
      end
      @answers_by_question_id[answer.question_id][answer.answer] = answer.answer
    end
  end

end
