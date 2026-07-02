# Create (or update the password of) a user from the credentials, falling back
# to a demo account.
email = Rails.application.credentials.dig(:user, :email).presence || "demo@example.com"
password = Rails.application.credentials.dig(:user, :password).presence || "password"

user = User.find_or_initialize_by(email: email)
user.password = password
user.save!

puts "Ensured user #{user.email}."

# Seed the user's nutrition goals from the credentials, if present.
goals = Rails.application.credentials.dig(:user_settings)
if goals.present?
  user.settings_or_build.update!(goals.slice(*UserSettings::GOALS))
  puts "Set nutrition goals for #{user.email}."
end
