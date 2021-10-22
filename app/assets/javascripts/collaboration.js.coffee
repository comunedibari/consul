App.Collaboration =

  initialize: ->
    $('form#new_collaboration_answer input.button').hide()
    $('form#new_collaboration_answer input[type=radio]').on
      click: ->
        $('form#new_collaboration_answer').submit()

    $('form#draft_version_go_to_version input.button').hide()
    $('form#draft_version_go_to_version select').on
      change: ->
        $('form#draft_version_go_to_version').submit()
