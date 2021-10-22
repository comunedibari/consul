module ApplicationHelper


  def isBlockedPrivacy
    #if (session["consensoPrivacyGeo"] != nil && session["consensoPrivacy"] !=nil)
    #if session["consensoPrivacyGeo"] == false || session["consensoPrivacy"] == false
    #    return true
    #end
    #end
    #return false
    current_user && !User.find(current_user.id).privacy #!current_user.privacy
  end


  def total_resource_count(resources,valid_filters)
    @total_resources_num = 0
    valid_filters.each do |filter|
      @total_resources_num = @total_resources_num.to_i + resources.send(filter).count.to_i
    end
    @total_resources_num
  end

  def platform_name
    Setting['org_name',User.pon_id].to_s
  end


  def home_page?
    return false if user_signed_in?
    # Using path because fullpath yields false negatives since it contains
    # parameters too
    request.path == '/'
  end

  def opendata_page?
    request.path == '/opendata'
  end

  # if current path is /debates current_path_with_query_params(foo: 'bar') returns /debates?foo=bar
  # notice: if query_params have a param which also exist in current path, it "overrides" (query_params is merged last)
  def current_path_with_query_params(query_parameters)
    url_for(request.query_parameters.merge(query_parameters))
  end

  def markdown(text)
    return text if text.blank?

    # See https://github.com/vmg/redcarpet for options
    render_options = {
      filter_html:     false,
      hard_wrap:       true,
      link_attributes: {  target: "_blank" }
    }
    renderer = Redcarpet::Render::HTML.new(render_options)
    extensions = {
      autolink:           true,
      fenced_code_blocks: true,
      lax_spacing:        true,
      no_intra_emphasis:  true,
      strikethrough:      true,
      superscript:        true
    }
    Redcarpet::Markdown.new(renderer, extensions).render(text).html_safe
  end

  def author_of?(authorable, user)
    return false if authorable.blank? || user.blank?
    authorable.author_id == user.id
  end

  def back_link_to(destination = :back, text = t("shared.back"))
    link_to destination, class: "back mb-3" do
      content_tag(:span, nil, class: "icon-angle-left") + text
    end
  end

  def image_path_for(filename)
    SiteCustomization::Image.image_path_for(filename) || filename
  end

  def content_block(name, locale)
    SiteCustomization::ContentBlock.block_for(name, locale)
  end

  def kaminari_path(url)
    "#{root_url.chomp("\/")}#{url}"
  end
end
