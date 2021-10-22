App.Crowdfunding =

  initialize: ->
        $('.prova').hover -> 
            title = "image"
            $(this).data('tipText', title).removeAttr('title')
            $('<p class="tooltip_p"></p>')
            .text(title)
            .appendTo('body')
            .fadeIn('slow')

        $('.prova') ->
            $('.tooltip_p').remove()

        $('.prova').mousemove( (e) ->  
                mousex = e.pageX + 20; #Get X coordinates
                mousey = e.pageY + 10; #Get Y coordinates
                $('.tooltip_p')
                .css({ top: mousey, left: mousex })
        )
