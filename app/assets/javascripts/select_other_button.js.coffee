
App.SelectOtherButton =


  initialize: ->
    buttonId = 'other_button_question_'
    fieldId = 'other_field_question_'

    $('div[id^="' + buttonId + '"]').on 'click', ->
      $this = $(this)
      sel_id = this.id.replace(buttonId, '')
      answer_div = $('div[id="' + fieldId + sel_id + '"]')
      #if answer_div.is(':visible')
      #  answer_div.hide()
      #else
      #  answer_div.show()

