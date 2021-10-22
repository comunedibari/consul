class Ability
  include CanCan::Ability

  def initialize(user,params=nil, isBlockedPrivacy=nil)
    # If someone can hide something, he can also hide it
    # from the moderation screen
    alias_action :hide_in_moderation_screen, to: :hide

    if user # logged-in users
      merge Abilities::Valuator.new(user,params,isBlockedPrivacy) if user.valuator?

      if user.administrator?
        merge Abilities::Administrator.new(user,params,isBlockedPrivacy)
      elsif user.moderator?
        merge Abilities::Moderator.new(user,params,isBlockedPrivacy)
      else
        merge Abilities::Common.new(user,params,isBlockedPrivacy)
      end
    else
      merge Abilities::Everyone.new(user,params,isBlockedPrivacy)
    end
  end

end
