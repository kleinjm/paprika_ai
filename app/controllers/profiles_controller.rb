class ProfilesController < ApplicationController
  def show
    @settings = current_user.settings

    staple_ids = current_user.user_staple_recipes.pluck(:recipe_id)
    @staple_joins = current_user.user_staple_recipes.index_by(&:recipe_id)
    @staple_recipes = Paprika::Recipe.not_trashed_in(staple_ids)
    @available_recipes = Paprika::Recipe.not_trashed_excluding(staple_ids)
  end
end
