class UserSettingsController < ApplicationController
  def edit
    @settings = current_user.settings_or_build
  end

  def update
    @settings = current_user.settings_or_build

    if @settings.update(settings_params)
      redirect_to profile_path, notice: "Nutrition goals updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    params.require(:user_settings).permit(:calorie_goal, :protein_goal, :carbs_goal, :fat_goal)
  end
end
