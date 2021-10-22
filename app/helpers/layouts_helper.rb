module LayoutsHelper

  def layout_menu_link_to(text, path, is_active, options)

    if path.include?('process_type=1') && is_active
      is_active = @current_type_process == '1'
    end

    if path.include?('process_type=2') && is_active
      is_active = @current_type_process == '2'
    end
         
    if is_active
      content_tag(:span, t('shared.you_are_in'), class: 'show-for-sr') + ' ' +
        link_to(text, path, options.merge(class: "active"))
    else
      link_to(text, path, options)
    end
  end

end
