App.Imageable =

  initialize: ->
    inputFiles = $('.js-image-attachment')
    $.each inputFiles, (index, input) ->
      App.Imageable.initializeDirectUploadInput(input)

    $( "div[id^='nested-image']" ).each ( index, element )->
      $(element).on 'cocoon:after-remove', (e, insertedItem) ->
        $( "div[id^='image_temp']" ).each ( index, element_d )->
          if !$.trim($(element_d).html())            
            $(element).attr('id')
            App.Imageable.unlockUploads(element)
            $(element_d).remove()
        

      $(element).on 'cocoon:after-insert', (e, nested_image) ->
        input = $(nested_image).find('.js-image-attachment')        
        div_element = $(nested_image).parent("div[id^='nested-image']")
        input["lockUpload"] = div_element.find('.image:visible').length >= div_element.data('max-images-allowed')
        App.Imageable.initializeDirectUploadInput(input)
        
        # console.log(e)
        # console.log("div_element.find('.image:visible').length") 
        # console.log(div_element.find('.image:visible').length)

        App.Imageable.lockUploads(div_element) if input["lockUpload"]    
        App.Imageable.showNotice(div_element) if input["lockUpload"]




  initializeDirectUploadInput: (input) ->

    inputData = @buildData([], input)

    @initializeRemoveCachedImageLink(input, inputData)

    $(input).fileupload

      paramName: "attachment"

      formData: null

      add: (e, data) ->
        data = App.Imageable.buildFileUploadData(e, data)
        App.Imageable.clearProgressBar(data)
        App.Imageable.setProgressBar(data, 'uploading')
        data.submit()

      change: (e, data) ->
        $.each data.files, (index, file) ->
          App.Imageable.setFilename(inputData, file.name)

      fail: (e, data) ->
        $(data.cachedAttachmentField).val("")
        App.Imageable.clearFilename(data)
        App.Imageable.setProgressBar(data, 'errors')
        App.Imageable.clearInputErrors(data)
        App.Imageable.setInputErrors(data)
        App.Imageable.clearPreview(data)
        $(data.destroyAttachmentLinkContainer).find("a.delete:not(.remove-nested)").remove()
        $(data.addAttachmentLabel).addClass('error')
        $(data.addAttachmentLabel).show()

      done: (e, data) ->
        $(data.cachedAttachmentField).val(data.result.cached_attachment)
        App.Imageable.setTitleFromFile(data, data.result.filename)
        App.Imageable.setProgressBar(data, 'complete')
        App.Imageable.setFilename(data, data.result.filename)
        App.Imageable.clearInputErrors(data)
        $(data.addAttachmentLabel).hide()
        $(data.wrapper).find(".attachment-actions").removeClass('small-12').addClass('small-6 float-right')
        $(data.wrapper).find(".attachment-actions .action-remove").removeClass('small-3').addClass('small-12')
        App.Imageable.setPreview(data)

        destroyAttachmentLink = $(data.result.destroy_link)
        $(data.destroyAttachmentLinkContainer).html(destroyAttachmentLink)
        $(destroyAttachmentLink).on 'click', (e) ->
          e.preventDefault()
          e.stopPropagation()
          App.Imageable.doDeleteCachedAttachmentRequest(this.href, data)
        div_element = $(data.wrapper).closest("div[id^='nested-images']")
        App.Imageable.showNotice(div_element) if input["lockUpload"]

      progress: (e, data) ->
        progress = parseInt(data.loaded / data.total * 100, 10)
        $(data.progressBar).find('.loading-bar').css 'width', progress + '%'
        return

  buildFileUploadData: (e, data) ->
    data = @buildData(data, e.target)
    return data

  buildData: (data, input) ->
    wrapper = $(input).closest('.direct-upload')
    data.input = input
    data.wrapper = wrapper
    data.progressBar = $(wrapper).find('.progress-bar-placeholder')
    data.preview = $(wrapper).find('.image-preview')
    data.errorContainer = $(wrapper).find('.attachment-errors')
    data.fileNameContainer = $(wrapper).find('p.file-name')
    data.destroyAttachmentLinkContainer = $(wrapper).find('.action-remove')
    data.addAttachmentLabel = $(wrapper).find('.action-add label')
    data.cachedAttachmentField = $(wrapper).find("input[name$='[cached_attachment]']")
    data.titleField = $(wrapper).find("input[name$='[title]']")
    $(wrapper).find('.progress-bar-placeholder').css('display', 'block')
    return data

  clearFilename: (data) ->
    $(data.fileNameContainer).text('')
    $(data.fileNameContainer).hide()

  clearInputErrors: (data) ->
    $(data.errorContainer).find('small.error').remove()

  clearProgressBar: (data) ->
    $(data.progressBar).find('.loading-bar').removeClass('complete errors uploading').css('width', "0px")

  clearPreview: (data) ->
    $(data.wrapper).find('.image-preview').remove()

  setFilename: (data, file_name) ->
    $(data.fileNameContainer).text(file_name)
    $(data.fileNameContainer).show()

  setProgressBar: (data, klass) ->
    $(data.progressBar).find('.loading-bar').addClass(klass)

  setTitleFromFile: (data, title) ->
    if $(data.titleField).val() == ""
      $(data.titleField).val(title)

  setInputErrors: (data) ->
    errors = '<small class="error">' + data.jqXHR.responseJSON.errors + '</small>'
    $(data.errorContainer).append(errors)

  lockUploads: (div_element)->
    val = $(div_element).parent()
    val2 =val.find('#new_image_link')
    val2.addClass('hide')

  unlockUploads: (div_element) ->
    val = $(div_element).parent()    
    val2 =val.find('#new_image_link')
    $(val2).removeClass('hide')
    val3 =val.find('#max-images-notice')
    val3.addClass('hide')

  showNotice: (div_element) ->
    val = $(div_element).parent()    
    val2 =val.find('#max-images-notice')
    $(val2).removeClass('hide')

  setPreview: (data) ->
    image_preview = '<div class="small-12 column text-center image-preview"><figure><img src="' + data.result.attachment_url + '" class="cached-image"/></figure></div>'
    if $(data.preview).length > 0
      $(data.preview).replaceWith(image_preview)
    else
      $(image_preview).insertBefore($(data.wrapper).find(".attachment-actions"))
      data.preview = $(data.wrapper).find('.image-preview')

  doDeleteCachedAttachmentRequest: (url, data) ->
    $.ajax
      type: "POST"
      url: url
      dataType: "json"
      data: { "_method": "delete" }
      complete: ->
        $(data.cachedAttachmentField).val("")
        $(data.addAttachmentLabel).show()

        App.Imageable.clearFilename(data)
        App.Imageable.clearInputErrors(data)
        App.Imageable.clearProgressBar(data)
        App.Imageable.clearPreview(data)

        div_element = $(data.wrapper).closest("#image_temp")
        div_element = $(div_element).parent("div[id^='nested-image']") 
        App.Imageable.unlockUploads(div_element)
        $(data.wrapper).find(".attachment-actions").addClass('small-12').removeClass('small-6 float-right')
        $(data.wrapper).find(".attachment-actions .action-remove").addClass('small-3').removeClass('small-12')

        if $(data.input).data('nested-image') == true
          $(data.wrapper).remove()
        else
          $(data.wrapper).find('a.remove-cached-attachment').remove()

  initializeRemoveCachedImageLink: (input, data) ->
    wrapper = $(input).closest(".direct-upload")
    remove_image_link = $(wrapper).find('a.remove-cached-attachment')
    $(remove_image_link).on 'click', (e) ->
      e.preventDefault()
      e.stopPropagation()
      App.Imageable.doDeleteCachedAttachmentRequest(this.href, data)

  removeImage: (id) ->
    $('#' + id).remove()
    $("#new_image_link").removeClass('hide')
