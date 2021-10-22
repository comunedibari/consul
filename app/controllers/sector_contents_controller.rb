class SectorContentsController < ApplicationController
  
    load_and_authorize_resource
  
=begin   def destroy
      respond_to do |format|
        format.html do
          if @document.destroy
            flash[:notice] = t "documents.actions.destroy.notice"
          else
            flash[:alert] = t "documents.actions.destroy.alert"
          end
          redirect_to params[:from]
        end
        format.js do
          if @document.destroy
            flash.now[:notice] = t "documents.actions.destroy.notice"
          else
            flash.now[:alert] = t "documents.actions.destroy.alert"
          end
        end
      end
    end
=end
  
  end
  