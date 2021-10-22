App.SetOpenAnswer =

  initialize: ->
    if other? && $('#answer_title').val() == other
      $('#open_answer_check').prop('checked', true)

    $('#open_answer_check').on 'click', ->
      $this = $(this)
      if ($this.is(':checked'))
        parent_id = other
        $('#answer_title').val(parent_id)
        $('#answer_title').prop("readonly",true)
        $('#title_answer').hide()
      else
        $('#answer_title').val("")
        $('#answer_title').prop("readonly",false)
        $('#title_answer').show()

    $('#open_answer_check').on 'load', ->
      console.log(test)






