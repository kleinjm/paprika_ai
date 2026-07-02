class RecipesController < ApplicationController
  def show
    @recipe = Paprika::Recipe.find_by!(Z_PK: params[:id])
  end
end
