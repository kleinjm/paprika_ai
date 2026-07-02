class ProfilesController < ApplicationController
  def show
    @settings = current_user.settings
  end
end
