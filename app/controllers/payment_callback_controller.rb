class PaymentCallbackController < ActionController::Base
    
    skip_authorization_check
 
    def wsdl
      render :file=>"payment_callback/wsdl.xml", :content_type => 'application/xml'
    end

    def paymentResponse

      xml_resp = request.body.read
      parsedXml = Hash.from_xml(xml_resp)
      
      entry = parsedXml['Envelope']['Body']

      if !entry.nil? and entry.has_key?("paymentDone") and entry['paymentDone'].has_key?("arg0")
        
        data = entry['paymentDone']['arg0']

        set_payment_done data
    
      elsif !entry.nil? and entry.has_key?("paymentBefore") and entry['paymentBefore'].has_key?("arg0")

        data = entry['paymentBefore']['arg0']
        @outcome = { 
          :action => "paymentBefore",
          :esito => "OK",
          :idPag => data["identificativoPagamento"],
          :infoAgg => data["infoAggiuntive"],
          :msgErr => ""
        }

      elsif !entry.nil? and entry.has_key?("paymentRollback") and entry['paymentRollback'].has_key?("arg0")

        data = entry['paymentRollback']['arg0']
        @outcome = { 
          :action => "paymentRollback",
          :esito => "OK",
          :idPag => data["identificativoPagamento"],
          :infoAgg => data["infoAggiuntive"],
          :msgErr => ""
        }

      else

        @outcome = { 
          :action => "paymentDone",
          :esito => "KO",
          :idPag => "",
          :infoAgg => "",
          :msgErr => "Errore durante il completamento dell'operazione."
        }

      end
      logger.info "----outcome: " + @outcome.inspect
      render :file=>"payment_callback/paymentResponse.xml", :content_type => 'text/xml'

    end

    private

    def set_payment_done data

      #items = UserInvestment.where(payment_id: data['identificativoPagamento']).where(credit_id: data['identificativoCredito']).where(status: 0)
      items = UserInvestment.where(payment_id: data['identificativoPagamento']).where(credit_id: data['identificativoCredito'])
      if items.count > 0

        item = items.first
        item.update_attribute(:status, :accepted)
        crowdfunding = item.crowdfunding
        #number_investors = UserInvestment.select(:user_id).where(crowdfunding_id: crowdfunding.id).where(status: 1).uniq.count
        #number_investors = UserInvestment.select(:investor).where(crowdfunding_id: crowdfunding.id).where(status: 1).uniq.count
        number_investors = UserInvestment.select(:fiscal_code).where(crowdfunding_id: crowdfunding.id).where(status: 1).uniq.count
        total_investment = UserInvestment.where(crowdfunding_id: crowdfunding.id).where(status: 1).sum(:value_investements)
        
        crowdfunding.update_attribute(:count_investors, number_investors)    
        crowdfunding.update_attribute(:total_investiment, total_investment)
      
        if crowdfunding.financed?
          insert_user_action(self.action_service, crowdfunding.author, "financed")
        end

        @outcome = { 
          :action => "paymentDone",
          :esito => "OK",
          :idPag => data['identificativoPagamento'],
          :infoAgg => "",
          :msgErr => ""
        }

      else

        @outcome = { 
          :action => "paymentDone",
          :esito => "KO",
          :idPag => data['identificativoPagamento'],
          :infoAgg => "",
          :msgErr => "Dati del pagamento non corretti"
        }

      end

    end
    
end