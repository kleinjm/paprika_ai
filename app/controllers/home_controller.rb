class HomeController < ApplicationController
  def index
    @recipes = Paprika::Recipe.all
    # @chat_gpt = ChatGptService.new
    @gemini = GeminiService.new
    @meal_plan_form = MealPlanForm.new
  end

  def analyze_recipe
    recipe = Paprika::Recipe.find(params[:id])
    @analysis = GeminiService.new.generate_content(prompt: "Analyze this recipe:\n\n#{recipe.name}\n\nIngredients:\n#{recipe.ingredients}\n\nInstructions:\n#{recipe.directions}")
    render turbo_stream: turbo_stream.replace("recipe_analysis", partial: "recipe_analysis", locals: { analysis: @analysis })
  end

  def suggest_substitutions
    @substitutions = GeminiService.new.generate_content(prompt: "Suggest substitutions for #{ingredient_param}")
    render turbo_stream: turbo_stream.replace("substitutions", partial: "substitutions", locals: { substitutions: @substitutions })
  end

  def suggest_meal_plan
    @meal_plan_form = MealPlanForm.new(meal_plan_params)

    prompt = @meal_plan_form.build_prompt
    @meal_plan = GeminiService.new.generate_content(prompt: prompt)
    render turbo_stream: turbo_stream.replace("meal_plan", partial: "meal_plan", locals: { meal_plan: @meal_plan })
  end

  def meal_plan_prompt_preview
    @meal_plan_form = MealPlanForm.new(meal_plan_params)

    prompt = @meal_plan_form.build_prompt
    render turbo_stream: turbo_stream.replace("meal_plan_prompt_preview", partial: "meal_plan_prompt_preview", locals: { prompt: prompt })
  end

  private

  def meal_plan_params
    params.require(:meal_plan_form).permit(:prompt, :num_recipes, category_ids: [])
  end

  def ingredient_param
    params.require(:substitution).permit(:ingredient)
  end
end
