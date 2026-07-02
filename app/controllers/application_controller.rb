class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Everything requires a signed-in user except Devise's own screens (login, etc.).
  before_action :authenticate_user!, unless: :devise_controller?
end
