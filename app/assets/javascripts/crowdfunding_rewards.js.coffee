App.CrowdfundingRewards =

  initialize: ->
     $('#crowdfunding_reward_ad').on
      click: ->
        App.CrowdfundingRewards.removeRewardNotice()

  removeRewardNotice: ->
    $('#notice_reward').remove()

  reset_form: (msg) ->    
    $('#min_investment').val('')
    $('#description').val('')
    $(msg).insertAfter($('#new_reward'))
