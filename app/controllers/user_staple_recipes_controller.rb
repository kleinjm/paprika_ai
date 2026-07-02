class UserStapleRecipesController < ApplicationController
  def create
    recipe_id = params[:recipe_id]
    current_user.user_staple_recipes.find_or_create_by!(recipe_id: recipe_id) if recipe_id.present?
    redirect_to profile_path, notice: "Staple recipe added."
  end

  def destroy
    current_user.user_staple_recipes.find(params[:id]).destroy
    redirect_to profile_path, notice: "Staple recipe removed."
  end
end
