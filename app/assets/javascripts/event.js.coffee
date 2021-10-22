App.Event = 

    initialize: ->
        jQuery.datetimepicker.setLocale('it');

        App.Event.initialize_date()

        $('.js-data-toggle').on
                click: ->
                  App.Event.toggleData()
        

    lockUploads: (div_element)->
        val = $(div_element).parent()
        val2 =val.find('#new_slot_link')
        val2.addClass('hide')

    unlockUploads: (div_element) ->
        val = $(div_element).parent()    
        val2 =val.find('#new_slot_link')
        $(val2).removeClass('hide')
        val3 =val.find('#max-slots-notice')
        val3.addClass('hide')

    showNotice: (div_element) ->
        val = $(div_element).parent()    
        val2 =val.find('#max-slots-notice')
        $(val2).removeClass('hide')

    toggleData: ->
        
        if $("#event_all_day_event").is(':checked')
            $( "input[id^='start_date_']" ).each (index, input) ->                
                $(input).datetimepicker({timepicker:false})
                $(input).datetimepicker({format:'d-m-Y'})
                $(input).val('')
            $( "input[id^='end_date_']" ).each (index, input) ->
                $(input).datetimepicker({timepicker:false})
                $(input).datetimepicker({format:'d-m-Y'})
                $(input).val('')

        else

            $( "input[id^='start_date_']" ).each (index, input) ->                
                $(input).datetimepicker({timepicker:true})
                $(input).datetimepicker({format:'d-m-Y H:i'})
                $(input).val('')
            $( "input[id^='end_date_']" ).each (index, input) ->
                $(input).datetimepicker({timepicker:true})
                $(input).datetimepicker({format:'d-m-Y H:i'})
                $(input).val('')

    initialize_date: ()->
        if $("#event_all_day_event").is(':checked')
            time = false                
            formato = 'd-m-Y'        
        else
            time = true
            formato = 'd-m-Y H:i'
        
        num_date = $( "div[id^='nested-slots']" ).find("div[id^='event_slot_']").length  
        num_date = num_date + $( "div[id^='nested-slots']" ).find("div[id^='new_event_slot']").length  
        max_slot = $( "div[id^='nested-slots']" ).data('max-slots-allowed')
        if num_date >= max_slot
            $("#max-slots-notice").removeClass('hide')
            $("#new_slot_link").addClass('hide')

        $( "input[id^='start_date_']" ).each (index, input) ->
            App.Event.formatData(input,time)
                            
        
        $( "input[id^='end_date_']" ).each (index, input) ->
            App.Event.formatData(input,time)

    formatData: (input,time)->
        data =  $(input).val()
        if data != ''
            data_arr = data.split(" ")
            data_arr[0]=data_arr[0].split("-")
            data_c = data_arr[0][2] + "-" + data_arr[0][1] + "-" + data_arr[0][0]
            if time
                data_arr[1]=data_arr[1].split(":")
                data_c = data_c + " " + data_arr[1][0] + ":" + data_arr[1][1]
            if data_arr[0][2].length == 2
                $(input).val(data_c)