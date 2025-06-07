class MealPlanForm
  include ActiveModel::Model

  DEFAULT_PROMPT = "Suggest a meal plan for this week"

  attr_accessor :category_ids, :prompt, :num_recipes

  validates :num_recipes, numericality: { greater_than: 0 }, allow_nil: true

  def initialize(attributes = {})
    super
    @prompt ||= DEFAULT_PROMPT
    @num_recipes ||= 4
  end

  def build_prompt
    recipe_json = recipes.map(&:to_ai_json).to_json
    base = prompt.presence || DEFAULT_PROMPT

    if num_recipes.present? && num_recipes.to_i > 0
      "#{base}. Select EXACTLY #{num_recipes} recipes from this list: #{recipe_json}. "\
      "Return the list or recipe names, one per line. If you have any reasoning for this list, skip a line and then explain your reasoning."
    else
      "#{base} for #{recipe_json}. Return the IDs of the recipes you selected."
    end
  end

  private

  def recipes
    if category_ids.present?
      Paprika::Recipe.joins(:recipe_categories).where(ZRECIPECATEGORY: { Z_PK: category_ids }).distinct
    else
      Paprika::Recipe.all
    end
  end
end
