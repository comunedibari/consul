App.CheckInvestmentFiscalData =

    initialize: ->
        $('#investment_fiscal_data').on
            click: ->
                $('#investment_check').prop('checked', true)
  