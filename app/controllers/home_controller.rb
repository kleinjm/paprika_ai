class HomeController < ApplicationController
  def index
    @recipes = Paprika::Recipe.all
    @chat_gpt = ChatGptService.new
  end

  def analyze_recipe
    recipe = Paprika::Recipe.find(params[:id])
    @analysis = ChatGptService.new.analyze_recipe(recipe)
    render turbo_stream: turbo_stream.replace("recipe_analysis", partial: "recipe_analysis", locals: { analysis: @analysis })
  end

  def suggest_substitutions
    ingredient = params[:ingredient]
    @substitutions = ChatGptService.new.suggest_substitutions(ingredient)
    render turbo_stream: turbo_stream.replace("substitutions", partial: "substitutions", locals: { substitutions: @substitutions })
  end

  def suggest_meal_plan
    recipes = Paprika::Recipe.all
    @meal_plan = ChatGptService.new.suggest_meal_plan(recipes)
    render turbo_stream: turbo_stream.replace("meal_plan", partial: "meal_plan", locals: { meal_plan: @meal_plan })
  end
end
