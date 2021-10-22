
App.UncheckGeozoneRestricted =


  initialize: ->

    $('[id="poll_geozone_restricted"]').on 'click', ->
      $this = $(this)
      if !this.checked
        $("input[id^='poll_geozone_ids_']").attr('checked',false)
