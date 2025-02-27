module AdminHelper

  def side_menu
    render "/#{namespace}/menu"
  end

  def namespaced_root_path
    "/#{namespace}"
  end

  def namespaced_header_title
    if current_user.administrator? || current_user.moderator?
      t("#{namespace}.header.title")
    else
      t("#{namespace}.header.title_user")
    end
  end

  def menu_tags?
    ["tags"].include?(controller_name)
  end

  def menu_moderated_content?
    ["Admin::Moderation::Legislation","Admin::Moderation"].include?(controller.class.parent.to_s)
    #["proposals","crowdfundings","legislation_proposals","reportings", "processes", "agreements", "debates", "comments", "hidden_users", "events"].include?(controller_name) && controller.class.parent != Admin::Legislation
  end

  def menu_budget?
    ["spending_proposals"].include?(controller_name) && controller.class.parent == Admin::Legislation
  end

  def menu_asset?
    ["assets","moderable_bookings"].include?(controller_name)
  end

  def menu_legislation_processes?
    #["process_works","process_chances","questions"].include?(controller_name)
    ["process_works","process_chances"].include?(controller_name)
  end

  def menu_collaboration_agreements?
    ["agreements"].include?(controller_name)
  end  

  def menu_legislation_proposals?
    ["legislation_proposals"].include?(controller_name) 
  end  

  def menu_legislation_process_processes_proposals?
    ["process_processes_proposals","crowdfundings", "agreements","agreement_requirements", "subscriptions"].include?(controller_name)
  end

  def menu_crowdfundings?
    ["crowdfundings"].include?(controller_name)
  end

  def menu_content_management?
    ["admin/legislation/process_processes_proposals","admin/legislation/process_typologies"].include?(controller_path)
    #["crowdfundings","process_processes_proposals","agreements","agreement_requirements"].include?(controller_name)
  end

  def menu_polls?
    %w[polls questions officers booths officer_assignments booth_assignments recounts results shifts answers].include?(controller_name)
  end

  def menu_profiles?
    %w[administrators organizations officials moderators valuators managers users activity].include?(controller_name)
  end

  def menu_banners?
    ["banner"].include?(controller_name)
  end

  def menu_customization?
    ["pages", "images", "content_blocks"].include?(controller_name)
  end

  def official_level_options
    options = [["", 0]]
    (1..5).each do |i|
      options << [[t("admin.officials.level_#{i}"), setting["official_level_#{i}_name"]].compact.join(': '), i]
    end
    options
  end

  def admin_select_options
    Administrator.all.order('users.username asc').includes(:user).collect { |v| [ v.name, v.id ] }
  end

  def sector_email_verified(sector)
    if (sector.user_id)
       sector.user.email
    else 
         ' '
    end
    
  end

  def admin_submit_action(resource)
    resource.persisted? ? "edit" : "new"
  end

  def user_roles(user)
    roles = []
    roles << "Amministatore" if user.administrator?
    roles << "Moderatore" if user.moderator?
    roles << :valuator if user.valuator?
    roles << :manager if user.manager?
    roles << :poll_officer if user.poll_officer?
    roles << :official if user.official?
    roles << :organization if user.organization?
    roles
  end

  def display_user_roles(user)
    val = user_roles(user).join(", ")
    if val == ""
      val = "Cittadino"
    else
      val
    end
    val
  end

  def display_budget_goup_form(group)
    group.errors.messages.size > 0 ? "" : "display:none"
  end

  private

    def namespace
      n = controller.class.parent.name.downcase.gsub("::", "/")
      if n == 'admin/moderation'
        n = controller.class.parent.parent.name.downcase.gsub("::", "/")
      end
      if n == 'moderation/legislation'
        n = controller.class.parent.parent.name.downcase.gsub("::", "/")
      end
      if n == 'moderation/collaboration'
        n = controller.class.parent.parent.name.downcase.gsub("::", "/")
      end   
      if n == 'admin/moderation/legislation'
        n = controller.class.parent.parent.parent.name.downcase.gsub("::", "/")
      end
      if n == 'admin/moderation/collaboration'
        n = controller.class.parent.parent.parent.name.downcase.gsub("::", "/")
      end  
      n 
    end

end
