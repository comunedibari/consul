class PonsController < ApplicationController
  skip_authorization_check

  def index
    @pons = Pon.all
=begin    
    if User.pon_id > 0
      redirect_to root_path
    else
      @pons = Pon.all
    end
=end    
  end

end

