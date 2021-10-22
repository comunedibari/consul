App.CollaborationAllegations =

  toggle_comments: ->
    if !App.CollaborationAnnotatable.isMobile()
      $('.draft-allegation').toggleClass('comments-on')
      $('#comments-box').html('').hide()

  show_comments: ->
    if !App.CollaborationAnnotatable.isMobile()
      $('.draft-allegation').addClass('comments-on')

  initialize: ->
    $('.js-toggle-allegations .draft-panel').on
      click: (e) ->
        e.preventDefault()
        e.stopPropagation()
        if !App.CollaborationAnnotatable.isMobile()
          App.CollaborationAllegations.toggle_comments()

    $('.js-toggle-allegations').on
      click: (e) ->
        # Toggle comments when the section title is visible
        if !App.CollaborationAnnotatable.isMobile()
          if $(this).find('.draft-panel .panel-title:visible').length == 0
            App.CollaborationAllegations.toggle_comments()
