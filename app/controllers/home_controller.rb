class HomeController < ApplicationController
  def index
    @recipes = Paprika::Recipe.all
    # @chat_gpt = ChatGptService.new
    @gemini = GeminiService.new
  end

  def analyze_recipe
    recipe = Paprika::Recipe.find(params[:id])
    @analysis = GeminiService.new.analyze_recipe(recipe)
    render turbo_stream: turbo_stream.replace("recipe_analysis", partial: "recipe_analysis", locals: { analysis: @analysis })
  end

  def suggest_substitutions
    ingredient = params[:ingredient]
    @gemini = GeminiService.new
    @substitutions = @gemini.suggest_substitutions(ingredient)
    render turbo_stream: turbo_stream.replace("substitutions", partial: "substitutions", locals: { substitutions: @substitutions })
  end

  def suggest_meal_plan
    if category_ids.present?
      recipes = Paprika::Recipe.joins(:recipe_categories).where(ZRECIPECATEGORY: { Z_PK: category_ids }).distinct
    else
      recipes = Paprika::Recipe.all
    end
    @meal_plan = GeminiService.new.suggest_meal_plan(recipes:, prompt: params[:prompt])
    render turbo_stream: turbo_stream.replace("meal_plan", partial: "meal_plan", locals: { meal_plan: @meal_plan })
  end

  private

  def category_ids
    Array(params[:category_ids]).reject(&:blank?).map(&:to_i)
  end
end
