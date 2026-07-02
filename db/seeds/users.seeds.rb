# Create (or update the password of) a user from the credentials, falling back
# to a demo account.
email = Rails.application.credentials.dig(:user, :email).presence || "demo@example.com"
password = Rails.application.credentials.dig(:user, :password).presence || "password"

user = User.find_or_initialize_by(email: email)
user.password = password
user.save!

puts "Ensured user #{user.email}."
