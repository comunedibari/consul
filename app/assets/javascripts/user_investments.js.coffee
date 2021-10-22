 App.UserInvestments =

  #  initialize: ->
  #     $('#user_investment').on
  #      click: ->
  #        App.UserInvestments.removeNotice()

  #  removeNotice: ->
  #    $('#notice').remove()

  #  reset_form: (msg,count,tot_inv) ->    
  #    $('#value_investements').val('')
  #    $('#note_investements').val('')
  #    $(msg).insertAfter($('#new_investment'))
  #    $('#num_invest').text(count)
  #    $('#tot_inv').text(tot_inv+' €')

  display_error: (field_with_errors, error_html) ->
    alert "ewew"
    #$("div").remove(".callout")
    #$(error_html).insertAfter($("#{field_with_errors}"))
    