class RelatedContentsController < ApplicationController
  skip_authorization_check

  respond_to :html, :js

  def create
    if relationable_object && related_object
      if relationable_object.url != related_object.url
        RelatedContent.create(parent_relationable: @relationable, child_relationable: @related, author: current_user)

        flash[:success] = t('related_content.success')
      else
        flash[:error] = t('related_content.error_itself')
      end

    else
      flash[:error] = t('related_content.error', url: Rails.application.config.root_path)      
      #flash[:error] = t('related_content.error', url: Setting['url',User.pon_id])
    end
    redirect_to @relationable.url
  end

  def score_positive
    score(:positive)
  end

  def score_negative
    score(:negative)
  end

  private

  def score(action)
    @related = RelatedContent.find_by(id: params[:id])
    @related.send("score_#{action}", current_user)

    render template: 'relationable/_refresh_score_actions'
  end

  def valid_url?
    params[:url].start_with?(Rails.application.config.root_path)
    #params[:url].start_with?(Setting['url',User.pon_id]) || params[:url].start_with?(Setting['url_coll',User.pon_id])
  end

  def relationable_object
    @relationable = params[:relationable_klass].singularize.camelize.constantize.find_by(id: params[:relationable_id])
  end

  def related_object
    if valid_url?
      url = params[:url]

      related_klass = url.scan(/\/(#{RelatedContent::RELATIONABLE_PATH.join("|")})\//)                           
                          .flatten.map { |i| i.to_s }.join("::")
      related_id = url.match(/\/(\d+)(?!.*\/\d)/)[1]
  
      related_klass = RelatedContent::RELATIONABLE_MODELS[related_klass]
      @related = related_klass.singularize.camelize.constantize.find_by(id: related_id)
    # else
    #   nil
    end
  rescue
    nil
  end
end
