class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Everything requires a signed-in user except Devise's own screens (login, etc.).
  before_action :authenticate_user!, unless: :devise_controller?

  # Run each request in the user's time zone so "today" reflects their local
  # day, not UTC. Falls back to the app default (Pacific) when unavailable.
  around_action :use_user_time_zone

  private

  def use_user_time_zone(&block)
    zone = current_user&.settings&.time_zone
    Time.use_zone(zone.presence || Time.zone, &block)
  end
end
