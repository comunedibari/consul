App.Polls =
  generateToken: ->
    token = ''
    rand = ''
    for n in [0..5]
      rand = Math.random().toString(36).substr(2) # remove `0.`
      token = token + rand;

    token = token.substring(0, 64)
    return token

  replaceToken: ->
    for link in $('.js-question-answer')
      if link.type = ""
        token_param = link.search.slice(-6)
        if token_param == "token="
          link.href = link.href + @token

  display_error: (field_with_errors, error_html) ->
    console.log field_with_errors
    $("div").remove(".callout")
    $(error_html).insertAfter($("#{field_with_errors}"))

  reset_form: (id) ->
    console.log id
    $("div").remove(".callout")

  initialize: ->
    @token = App.Polls.generateToken()
    App.Polls.replaceToken()

    $(".js-question-answer").on
      click: =>
        token_message = $(".js-token-message")
        if !token_message.is(':visible')
          token_message.html(token_message.html() + "<br><strong>" + @token + "</strong>");
          token_message.show()
    false

    $(".zoom-link").on "click", (event) ->
      element = event.target
      answer = $(element).closest('div.answer')

      if $(answer).hasClass('medium-6')
        $(answer).removeClass("medium-6");
        $(answer).addClass("answer-divider");
        unless $(answer).hasClass('first')
          $(answer).insertBefore($(answer).prev('div.answer'));
      else
        $(answer).addClass("medium-6");
        $(answer).removeClass("answer-divider");
        unless $(answer).hasClass('first')
          $(answer).insertAfter($(answer).next('div.answer'));

