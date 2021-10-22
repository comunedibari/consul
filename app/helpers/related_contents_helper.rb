module RelatedContentsHelper

  def getFormUrl(related,params_url)
    url = ""
    if params_url.include?(setting['url'])
      url = setting['url'] 
    elsif params_url.include?(setting['url_coll'])
      url = setting['url_coll']
    else
      url = setting['url']
    end
    url = url + related.url
  end
end
