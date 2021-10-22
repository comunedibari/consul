
App.ShowQuestionDescription =


  initialize: ->
    buttonId = 'desc_button_'
    buttonAnswerId = 'desc_answer_button_'
    fieldId = 'desc_question_'
    fieldAnswerId = 'desc_answer_'

    $('div[id^="' + buttonId + '"]').on 'click', ->
      $this = $(this)
      sel_id = this.id.replace(buttonId, '')
      answer_div = $('div[id="' + fieldId + sel_id + '"]')
      if answer_div.is(':visible')
        answer_div.hide()
      else
        answer_div.show()

    $('div[id^="' + buttonAnswerId + '"]').on 'click', ->
      $this = $(this)
      sel_id = this.id.replace(buttonAnswerId, '')
      answer_div = $('div[id="' + fieldAnswerId + sel_id + '"]')
      if answer_div.is(':visible')
        answer_div.hide()
      else
        answer_div.show()

