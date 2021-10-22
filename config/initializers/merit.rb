# Use this hook to configure merit parameters
Merit.setup do |config|
  # Check rules on each request or in background
  # config.checks_on_each_request = true

  # Define ORM. Could be :active_record (default) and :mongoid
  # config.orm = :active_record

  # Add application observers to get notifications when reputation changes.
  # config.add_observer 'MyObserverClassName'

  # Define :user_model_name. This model will be used to grand badge if no
  # `:to` option is given. Default is 'User'.
  # config.user_model_name = 'User'

  # Define :current_user_method. Similar to previous option. It will be used
  # to retrieve :user_model_name object if no `:to` option is given. Default
  # is "current_#{user_model_name.downcase}".
  # config.current_user_method = 'current_user'
end


badge_id = 0

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Commentatore",
  level: "1",
  description: "Livello Matricola",
  custom_fields: { difficulty: :silver }
)

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Commentatore",
  level: "2",
  description: "Livello Junior",
  custom_fields: { difficulty: :silver }
)

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Commentatore",
  level: "3",
  description: "Livello Esperto",
  custom_fields: { difficulty: :silver }
)

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Commentatore",
  level: "4",
  description: "Livello Vip",
  custom_fields: { difficulty: :silver }
)


badge_id = 5

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Autore",
  level: "1",
  description: "Livello Matricola",
  custom_fields: { difficulty: :silver }
)

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Autore",
  level: "2",
  description: "Livello Junior",
  custom_fields: { difficulty: :silver }
)

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Autore",
  level: "3",
  description: "Livello Esperto",
  custom_fields: { difficulty: :silver }
)

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Autore",
  level: "4",
  description: "Livello Vip",
  custom_fields: { difficulty: :silver }
)



badge_id = 10

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Votante",
  level: "1",
  description: "Livello Matricola",
  custom_fields: { difficulty: :silver }
)

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Votante",
  level: "2",
  description: "Livello Junior",
  custom_fields: { difficulty: :silver }
)

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Votante",
  level: "3",
  description: "Livello Esperto",
  custom_fields: { difficulty: :silver }
)

Merit::Badge.create!(
  id: (badge_id = badge_id+1),
  name: "Votante",
  level: "4",
  description: "Livello Vip",
  custom_fields: { difficulty: :silver }
)






# Create application badges (uses https://github.com/norman/ambry)
# badge_id = 0
# [{
#   id: (badge_id = badge_id+1),
#   name: 'just-registered'
# }, {
#   id: (badge_id = badge_id+1),
#   name: 'best-unicorn',
#   custom_fields: { category: 'fantasy' }
# }].each do |attrs|
#   Merit::Badge.create! attrs
# end
