_t = (key) -> new Gettext().gettext(key)

App.CollaborationAnnotatable =

  makeEditableAndHighlight: (colour) ->
    sel = window.getSelection()
    if sel.rangeCount and sel.getRangeAt
      range = sel.getRangeAt(0)
    document.designMode = 'on'
    if range
      sel.removeAllRanges()
      sel.addRange range
    # Use HiliteColor since some browsers apply BackColor to the whole block
    if !document.execCommand('HiliteColor', false, colour)
      document.execCommand 'BackColor', false, colour
    document.designMode = 'off'
    return

  highlight: (colour) ->
    if window.getSelection
      # IE9 and non-IE
      try
        if !document.execCommand('BackColor', false, colour)
          App.CollaborationAnnotatable.makeEditableAndHighlight colour
      catch ex
        App.CollaborationAnnotatable.makeEditableAndHighlight colour
    else if document.selection and document.selection.createRange
      # IE <= 8 case
      range = document.selection.createRange()
      range.execCommand 'BackColor', false, colour
    return

  remove_highlight: ->
    $('[data-collaboration-draft-version-id] span[style]').replaceWith(->
      return $(this).contents()
    )
    return

  renderAnnotationComments: (event) ->
    if event.offset
      $("#comments-box").css({top: event.offset - $('.calc-comments').offset().top})

    if App.CollaborationAnnotatable.isMobile()
      return

    $.ajax
      method: "GET"
      url: event.annotation_url + "/annotations/" + event.annotation_id + "/comments"
      dataType: 'script'

  onClick: (event) ->
    event.preventDefault()
    event.stopPropagation()

    if App.CollaborationAnnotatable.isMobile()
      annotation_url = $(event.target).closest(".collaboration-annotatable").data("collaboration-annotatable-base-url")
      window.location.href = annotation_url + "/annotations/" + $(this).data('annotation-id')
      return

    $('[data-annotation-id]').removeClass('current-annotation')

    target = $(this)

    parents = target.parents('.annotator-hl')
    parents_ids = parents.map (_, elem) ->
      $(elem).data("annotation-id")

    annotation_id = target.data('annotation-id')
    $('[data-annotation-id="' + annotation_id + '"]').addClass('current-annotation')

    $('#comments-box').html('')
    App.CollaborationAllegations.show_comments()
    $("#comments-box").show()

    $.event.trigger
      type: "renderCollaborationAnnotation"
      annotation_id: target.data("annotation-id")
      annotation_url: target.closest(".collaboration-annotatable").data("collaboration-annotatable-base-url")
      offset: target.offset()["top"]

    parents_ids.each (i, pid) ->
      $.event.trigger
        type: "renderCollaborationAnnotation"
        annotation_id: pid
        annotation_url: target.closest(".collaboration-annotatable").data("collaboration-annotatable-base-url")

  isMobile: ->
    return window.innerWidth <= 652

  viewerExtension: (viewer) ->
    viewer._onHighlightMouseover = (event) ->
      return

  customShow: (position) ->
    $(@element).html ''
    # Clean comments section and open it
    $('#comments-box').html ''
    App.CollaborationAllegations.show_comments()
    $('#comments-box').show()

    annotation_url = $('[data-collaboration-annotatable-base-url]').data('collaboration-annotatable-base-url')
    $.ajax(
      method: 'GET'
      url: annotation_url + '/annotations/new'
      dataType: 'script').done (->
        $('#new_collaboration_annotation #collaboration_annotation_quote').val(@annotation.quote)
        $('#new_collaboration_annotation #collaboration_annotation_ranges').val(JSON.stringify(@annotation.ranges))
        $('#comments-box').css({top: position.top - $('.calc-comments').offset().top})

        unless  $('[data-collaboration-open-phase]').data('collaboration-open-phase') == false
          App.CollaborationAnnotatable.highlight('#7fff9a')
          $('#comments-box textarea').focus()

          $("#new_collaboration_annotation").on("ajax:complete", (e, data, status, xhr) ->
            App.CollaborationAnnotatable.app.destroy()
            if data.status == 200
              App.CollaborationAnnotatable.remove_highlight()
              $("#comments-box").html("").hide()
              $.ajax
                method: "GET"
                url: annotation_url + "/annotations/" + data.responseJSON.id + "/comments"
                dataType: 'script'
            else
              $(e.target).find('label').addClass('error')
              $('<small class="error">' + data.responseJSON[0] + '</small>').insertAfter($(e.target).find('textarea'))
            return true
          )
        return
    ).bind(this)

  editorExtension: (editor) ->
    editor.show = App.CollaborationAnnotatable.customShow

  scrollToAnchor: ->
    annotationsLoaded: (annotations) ->
      anchor = $(location).attr('hash')
      if anchor && anchor.startsWith('#annotation')
        ann_id = anchor.split("-")[-1..]

        checkExist = setInterval((->
          if $("span[data-annotation-id='" + ann_id + "']").length
            el = $("span[data-annotation-id='" + ann_id + "']")
            el.addClass('current-annotation')
            $('#comments-box').html('')
            App.CollaborationAllegations.show_comments()
            $('html,body').animate({scrollTop: el.offset().top})
            $.event.trigger
              type: "renderCollaborationAnnotation"
              annotation_id: ann_id
              annotation_url: el.closest(".collaboration-annotatable").data("collaboration-annotatable-base-url")
              offset: el.offset()["top"]
            clearInterval checkExist
          return
        ), 100)

  propotionalWeight: (v, max) ->
    Math.floor(v * 5 / (max + 1)) + 1

  addWeightClasses: ->
    annotationsLoaded: (annotations) ->
      return if annotations.length == 0
      weights = annotations.map (ann) -> ann.weight
      max_weight = Math.max.apply(null, weights)
      last_annotation = annotations[annotations.length - 1]

      checkExist = setInterval((->
        if $("span[data-annotation-id='" + last_annotation.id + "']").length
          for annotation in annotations
            ann_weight = App.CollaborationAnnotatable.propotionalWeight(annotation.weight, max_weight)
            el = $("span[data-annotation-id='" + annotation.id + "']")
            el.addClass('weight-' + ann_weight)
          clearInterval checkExist
        return
      ), 100)

  initialize: ->
    $(document).off("renderCollaborationAnnotation").on("renderCollaborationAnnotation", App.CollaborationAnnotatable.renderAnnotationComments)
    $(document).off('click', '[data-annotation-id]').on('click', '[data-annotation-id]', App.CollaborationAnnotatable.onClick)
    $(document).off('click', '[data-cancel-annotation]').on('click', '[data-cancel-annotation]', (e) ->
      e.preventDefault()
      $('#comments-box').html('')
      $('#comments-box').hide()
      App.CollaborationAnnotatable.remove_highlight()
      return
    )

    current_user_id = $('html').data('current-user-id')

    $(".collaboration-annotatable").each ->
      $this          = $(this)
      ann_type       = "collaboration_draft_version"
      ann_id         = $this.data("collaboration-draft-version-id")
      base_url       = $this.data("collaboration-annotatable-base-url")

      App.CollaborationAnnotatable.app = new annotator.App()
        .include ->
          beforeAnnotationCreated: (ann) ->
            ann["collaboration_draft_version_id"] = ann_id
            ann.permissions = ann.permissions || {}
            ann.permissions.admin = []
        .include(annotator.ui.main, {
          element: this,
          viewerExtensions: [App.CollaborationAnnotatable.viewerExtension],
          editorExtensions: [App.CollaborationAnnotatable.editorExtension]
        })
        .include(App.CollaborationAnnotatable.scrollToAnchor)
        .include(App.CollaborationAnnotatable.addWeightClasses)
        .include(annotator.storage.http, { prefix: base_url, urls: { search: "/annotations/search" } })

      App.CollaborationAnnotatable.app.start().then ->
        App.CollaborationAnnotatable.app.ident.identity = current_user_id

        options = {}
        options["collaboration_draft_version_id"] = ann_id
        App.CollaborationAnnotatable.app.annotations.load(options)
