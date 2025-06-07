class HomeController < ApplicationController
  def index
    @recipes = Paprika::Recipe.all
    # @chat_gpt = ChatGptService.new
    @gemini = GeminiService.new
  end

  def analyze_recipe
    recipe = Paprika::Recipe.find(params[:id])
    @analysis = GeminiService.new.generate_content(prompt: "Analyze this recipe:\n\n#{recipe.name}\n\nIngredients:\n#{recipe.ingredients}\n\nInstructions:\n#{recipe.directions}")
    render turbo_stream: turbo_stream.replace("recipe_analysis", partial: "recipe_analysis", locals: { analysis: @analysis })
  end

  def suggest_substitutions
    ingredient = params[:ingredient]
    @substitutions = GeminiService.new.generate_content(prompt: "Suggest substitutions for #{ingredient}")
    render turbo_stream: turbo_stream.replace("substitutions", partial: "substitutions", locals: { substitutions: @substitutions })
  end

  def suggest_meal_plan
    @meal_plan = GeminiService.new.generate_content(prompt: params[:prompt])
    render turbo_stream: turbo_stream.replace("meal_plan", partial: "meal_plan", locals: { meal_plan: @meal_plan })
  end

  def meal_plan_prompt_preview
    if category_ids.present?
      recipes = Paprika::Recipe.joins(:recipe_categories).where(ZRECIPECATEGORY: { Z_PK: category_ids }).distinct
    else
      recipes = Paprika::Recipe.all
    end
    num_recipes = params[:num_recipes].to_i if params[:num_recipes].present?
    prompt = build_meal_plan_prompt(params[:prompt], recipes, num_recipes)
    render turbo_stream: turbo_stream.replace("meal_plan_prompt_preview", partial: "meal_plan_prompt_preview", locals: { prompt: prompt })
  end

  private

  def category_ids
    Array(params[:category_ids]).reject(&:blank?).map(&:to_i)
  end

  def build_meal_plan_prompt(base_prompt, recipes, num_recipes)
    recipe_json = recipes.map(&:to_ai_json).to_json
    base = base_prompt.presence || "Suggest a meal plan for this week"
    if num_recipes.present? && num_recipes > 0
      "#{base}. Select EXACTLY #{num_recipes} recipes from this list: #{recipe_json}. "\
      "Return the list or recipe names, one per line. If you have any reasoning for this list, skip a line and then explain your reasoning."
    else
      "#{base} for #{recipe_json}. Return the IDs of the recipes you selected."
    end
  end
end
