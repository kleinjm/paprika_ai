class RecipesController < ApplicationController
  def show
    @recipe = Paprika::Recipe.find_by!(Z_PK: params[:id])
  end

  # Reached from the "Rewrite in shorthand" button on the show page. Shows the
  # current directions above a text input pre-filled with the AI-rewritten
  # shorthand version, for review/tweaking before saving.
  def edit
    @recipe = Paprika::Recipe.find_by!(Z_PK: params[:id])
    @original_directions = @recipe.directions
    @rewritten_directions = RecipeShorthand.new.rewrite(@recipe)
  end

  # Saves the edited directions. update_directions! pushes to the Paprika cloud
  # (the source of truth) and refreshes the local read-only cache.
  def update
    @recipe = Paprika::Recipe.find_by!(Z_PK: params[:id])
    @recipe.update_directions!(directions_param)
    redirect_to recipe_path(@recipe.id), notice: "Directions updated."
  end

  private

  def directions_param
    params.require(:recipe).permit(:directions)[:directions]
  end
end
