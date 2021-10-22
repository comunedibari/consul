# Be sure to restart your server when you modify this file.
#
# +grant_on+ accepts:
# * Nothing (always grants)
# * A block which evaluates to boolean (recieves the object as parameter)
# * A block with a hash composed of methods to run on the target object with
#   expected values (+votes: 5+ for instance).
#
# +grant_on+ can have a +:to+ method name, which called over the target object
# should retrieve the object to badge (could be +:user+, +:self+, +:follower+,
# etc). If it's not defined merit will apply the badge to the user who
# triggered the action (:action_user by default). If it's :itself, it badges
# the created object (new user for instance).
#
# The :temporary option indicates that if the condition doesn't hold but the
# badge is granted, then it's removed. It's false by default (badges are kept
# forever).

module Merit
  class BadgeRules
    include Merit::BadgeRulesMethods

    def initialize



=begin

      grant_on ['comments#create', 
                'moderation_comments#moderate', 
                'admin_moderation_comments#restore', 
                'admin_moderation_comments#confirm_hide'],  badge_id: 1, temporary: true, level: 1 do |comment|
        comment.user.comments.mod_approved.count.between?(1, 5) 
        #logger.debug "****************" + var1.to_s
      end
   

      grant_on ['comments#create', 
        'moderation_comments#moderate', 
        'admin_moderation_comments#restore', 
        'admin_moderation_comments#confirm_hide'],  badge_id: 2, temporary: true, level: 2 do |comment|
      comment.user.comments.mod_approved.count.between?(6, 10) 
        #logger.debug "****************" + var2.to_s
      end

      grant_on ['comments#create', 
        'moderation_comments#moderate', 
        'admin_moderation_comments#restore', 
        'admin_moderation_comments#confirm_hide'], badge_id: 3, temporary: true, level: 3 do |comment|
        comment.user.comments.mod_approved.count.between?(11, 15) 
        #logger.debug "****************" + var3.to_s
      end

      grant_on ['comments#create', 
        'moderation_comments#moderate', 
        'admin_moderation_comments#restore', 
        'admin_moderation_comments#confirm_hide'],  badge_id: 4, temporary: true, level: 4 do |comment|
        comment.user.comments.mod_approved.count > 15
        #logger.debug "****************" + var4.to_s
      end


      grant_on ['debates#create', 
        'moderation_debates#moderate', 
        'admin_moderation_debates#restore', 
        'admin_moderation_debates#confirm_hide'],  badge_id: 5, temporary: true, level: 1 do |resource|
        
        logger.debug "**********************" + var4.to_s
        resource.author.debates.mod_approved.count > 1
        #logger.debug "****************" + var4.to_s
      end

=end

      # If it creates user, grant badge
      # Should be "current_user" after registration for badge to be granted.
      # Find badge by badge_id, badge_id takes presidence over badge
      # grant_on 'users#create', badge_id: 7, badge: 'just-registered', to: :itself

      # If it has 10 comments, grant commenter-10 badge
      # grant_on 'comments#create', badge: 'commenter', level: 10 do |comment|
      #   comment.user.comments.count == 10
      # end

      # If it has 5 votes, grant relevant-commenter badge
      # grant_on 'comments#vote', badge: 'relevant-commenter',
      #   to: :user do |comment|
      #
      #   comment.votes.count == 5
      # end

      # Changes his name by one wider than 4 chars (arbitrary ruby code case)
      # grant_on 'registrations#update', badge: 'autobiographer',
      #   temporary: true, model_name: 'User' do |user|
      #
      #   user.name.length > 4
      # end
    end
  end
end
