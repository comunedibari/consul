App.Comments =

  add_comment: (parent_id, response_html,increment,msg_html) ->
    if increment == true
      $(response_html).insertAfter($("#js-comment-form-#{parent_id}"))
      this.update_comments_count()
    else
      $(msg_html).insertAfter($("#js-comment-form-#{parent_id}"))

  add_reply: (parent_id, response_html,increment,msg_html) ->
    if increment == true
      if $("##{parent_id} .comment-children").length == 0
        $("##{parent_id}").append("<li><ul id='#{parent_id}_children' class='list-unstyled comment-children'></ul></li>")
      $("##{parent_id} .comment-children:first").prepend($(response_html))
      this.update_comments_count()

      #aggiornamento conteggio risposte
      val = $("##{parent_id}_reply").children("a").find("#size").text().split(" ")
      val2 = $("##{parent_id}_reply").find("#size").text().split(" ")
      if val[0] == "" and val2[0] == "Senza"
        risp = "1 Risposta"
        $("##{parent_id}_reply").find("#size").text(risp)
      else if val[0] == ""
        val= parseInt(val2[0])+1
        risp = val+" Risposte"
        $("##{parent_id}_reply").find("#size").text(risp)
      else
        val= parseInt(val[0])+1
        risp = val+" Risposte"
        $("##{parent_id}_reply").children("a").find("#size").text(risp)
      
    else
      $(msg_html).insertAfter($("#js-comment-form-#{parent_id}"))


  update_comments_count: (parent_id) ->
    $(".js-comments-count").each ->
      new_val = $(this).text().trim().replace /\d+/, (match) -> parseInt(match, 10) + 1
      $(this).text(new_val)

  display_error: (field_with_errors, error_html) ->
    $("div").remove(".callout")
    $(error_html).insertAfter($("#{field_with_errors}"))

  reset_and_hide_form: (id) ->
    if($('#comment-as-rappr-legale-'+id).length > 0)
      if $('#comment-as-rappr-legale-'+id).is(':checked')
        $('#id-sector-'+id).toggle()
      $('#comment-as-rappr-legale-'+id).attr('checked',false);
    
    if($('#comment-as-administrator-'+id).length > 0)
      $('#comment-as-administrator-'+id).attr('checked',false);

    form_container = $("#js-comment-form-#{id}")
    input = form_container.find("form textarea")
    input.val('')
    form_container.hide()

  reset_form: (id) ->
    if($('#comment-as-rappr-legale-'+id).length > 0)
      if $('#comment-as-rappr-legale-'+id).is(':checked')
        $('#id-sector-'+id).toggle()
        $('#comment-as-rappr-legale-'+id).attr('checked',false);
    
    if($('#comment-as-administrator-'+id).length > 0)
      $('#comment-as-administrator-'+id).attr('checked',false);

    input = $("#js-comment-form-#{id} form textarea")
    input.val('')
    $("div").remove(".callout")
    $( "div[id^='new_document']" ).each ( index, element )->
      $(element).remove()
    $( "div[id^='image_temp']" ).each ( index, element )->
      $(element).remove()
    document.getElementById('comment_external_url').value = ''

  toggle_form: (id) ->
    $("#js-comment-form-#{id}").toggle()

  toggle_arrow: (id) ->
    arrow = "span##{id}_arrow"
    if $(arrow).hasClass("icon-arrow-right")
      $(arrow).removeClass("icon-arrow-right").addClass("icon-arrow-down")
    else
      $(arrow).removeClass("icon-arrow-down").addClass("icon-arrow-right")

  initialize: ->
    $('body .js-add-comment-link').each ->
      $this = $(this)

      unless $this.data('initialized') is 'yes'
        $this.on('click', ->          
          id = $(this).data().id
          App.Comments.toggle_form(id)
          false
        ).data 'initialized', 'yes'

    $('body .js-toggle-children').each ->
      $(this).on('click', ->
        children_container_id = "#{$(this).data().id}_children"
        $("##{children_container_id}").toggle('slow')
        App.Comments.toggle_arrow(children_container_id)
        $(this).children('.js-child-toggle').toggle()
        false
      )

    $('.js-toggle-comment-sector').each ->
      $this = $(this)
      unless $this.data('initialized') is 'yes'
        $(this).on('click', ->        
          id_this =   this.id
          val = id_this.split('-')
          id_val = val[val.length-1]
          if $('#comment-as-rappr-legale-'+id_val).is(':checked') and $('#comment-as-administrator-'+id_val).is(':checked')
            $('#comment-as-administrator-'+id_val).attr('checked',false);
          $('#id-sector-'+id_val).toggle()
        ).data 'initialized', 'yes'

    $('.js-toggle-as-admin').each ->
      $this = $(this)
      unless $this.data('initialized') is 'yes'
        $(this).on('click', ->
          id_this =   this.id
          val = id_this.split('-')
          id_val = val[val.length-1]
          if $('#comment-as-rappr-legale-'+id_val).is(':checked') and $('#comment-as-administrator-'+id_val).is(':checked')
            $('#comment-as-rappr-legale-'+id_val).attr('checked',false);
            $('#id-sector-'+id_val).toggle()
        ).data 'initialized', 'yes'      
