class MealPlanForm
  include ActiveModel::Model

  DEFAULT_PROMPT = "Suggest a meal plan for this week. I plan on cooking 2 times this week, 2 meals each time and I will eat leftovers in between. I have all the cooking equipment I need. Assume I have basic spices and oils. All the fresh ingredients are needed so consider recipes with overlapping ingredients that often are too much for one recipe, ie. parsley, cilantro, etc. Consider the use of the stove and oven. I do not want two recipes on the same night that both require stovetop cooking as their main cooking method due to space constraints. If a recipe requires only some space, ie. a small pot of rice, but does not require the entire stove, then it is fine to cook it on the same night. Consider the type of cuisine. For example, pair a Mexican entree with a Mexican side dish."

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
      "Return a list of recipe names grouped under the day they are to be cooked. If you have any reasoning for this list, skip a line and then explain your reasoning."
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
