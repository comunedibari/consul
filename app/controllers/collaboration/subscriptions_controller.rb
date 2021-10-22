class Collaboration::SubscriptionsController < ApplicationController
     

    load_and_authorize_resource

    before_action :load_data, only: [:new, :create, :show]

    
    include Gamification
    
    gamification "Collaboration::Subscription"




    def new
        @collaboration_subscription = Collaboration::Subscription.new
    end

    def show
        @subscriptions = @collaboration_agreement.subscriptions
        @subscription = Collaboration::Subscription.find(params[:id])
    end
    def create
        @collaboration_subscription = Collaboration::Subscription.new(subscription_params.merge(user: current_user))


        documents_attached = Array.new
        if params[:collaboration_subscription][:documents_attributes]
            params[:collaboration_subscription][:documents_attributes].each do |document|
                documents_attached.push(document[1][:title].to_s)
            end
        end

        requirements =  Array.new
        @collaboration_agreement.agreement_requirements.each do |requirement|
             requirements.push(requirement.title.to_s)
        end
        
        doc_ = ""
        requirements.each do |requirement|
            if documents_attached.include?(requirement)   
                #ok
            else
                doc_ = doc_ + ", " if doc_ != ""
                doc_ = doc_ + requirement.to_s
            end
        end

        if doc_ != ""
            flash[:error] =  t('verification.collaboration.already_subscription.agreement_requirement_not_found',title: doc_)
            redirect_to new_collaboration_agreement_subscription_path(@collaboration_agreement)        
        elsif @collaboration_subscription.save
            @collaboration_agreement.subscriptions_count = @collaboration_agreement.subscriptions_count.to_i + 1
            @collaboration_agreement.save
            notice = t('collaboration.subscriptions.create.notice')
            redirect_to collaboration_agreement_path(@collaboration_agreement), notice: notice
        else
            render :new
        end

    end
    

    def load_data
        @collaboration_agreement = Collaboration::Agreement.find(params[:agreement_id])
    end



    def agreement_type
        [2]
    end

    private
        def subscription_params
            params.require(:collaboration_subscription).permit(:note, :collaboration_agreement_id,
                documents_attributes: [:id, :title, :attachment, :cached_attachment, :user_id, :_destroy]
                )        
        end




end
