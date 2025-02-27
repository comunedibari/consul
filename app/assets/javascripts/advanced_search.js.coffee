App.AdvancedSearch =

  advanced_search_terms: ->
    $('#js-advanced-search').data('advanced-search-terms')

  toggle_form: (event) ->
    event.preventDefault()
    $('#js-advanced-search').slideToggle()

  toggle_date_options: ->
    if $('#js-advanced-search-date-min').val() == 'custom'
      $('#js-custom-date').show()
      $( ".js-calendar" ).datepicker( "option", "disabled", false )
    else
      $('#js-custom-date').hide()
      $( ".js-calendar" ).datepicker( "option", "disabled", true )
      $("#advanced_search_date_min").val('')
      $("#advanced_search_date_max").val('')
      $("#advanced_search_date_min_event").val('')
      $("#advanced_search_date_max_event").val('')

  init_calendar: ->
    locale = $('#js-locale').data('current-local')

    if locale == undefined
      locale = 'it'

    else
      if locale == 'en'
        locale = ''

    $.datepicker.setDefaults($.datepicker.regional[locale])

    $('.js-calendar').datepicker
      regional: locale
      maxDate: "+0d"
    $('.js-calendar-full').datepicker
      regional: locale

  initialize: ->
    App.AdvancedSearch.init_calendar()

    if App.AdvancedSearch.advanced_search_terms()
      $('#js-advanced-search').show()
      App.AdvancedSearch.toggle_date_options()

    $('#js-advanced-search-title').on
      click: (event) ->
        App.AdvancedSearch.toggle_form(event)

    $('#js-advanced-search-date-min').on
      change: ->
        App.AdvancedSearch.toggle_date_options()


    $('#js-advanced-search-date-min-event').on
      change: ->
        App.AdvancedSearch.toggle_date_options()
