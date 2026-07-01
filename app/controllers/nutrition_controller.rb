class NutritionController < ApplicationController
  MEAL_WINDOW_BACK = 7
  MEAL_WINDOW_AHEAD = 2

  def show
    @date = parse_date(params[:date])
    @entries = NutritionEntry.for_day(@date)
    @totals = NutritionEntry.totals_for(@date)
    load_recipe_choices
  end

  def log
    @date = parse_date(params[:date])
    message = params[:message].to_s.strip

    if message.blank?
      @reply = "Tell me what you ate and I'll log it."
    else
      recipes = selected_recipes
      result = NutritionParser.new.parse(message, recipes: recipes)
      persist_entries(result.entries, message, recipes)
      @reply = result.reply
    end

    @entries = NutritionEntry.for_day(@date)
    @totals = NutritionEntry.totals_for(@date)
    load_recipe_choices

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to nutrition_path(date: @date) }
    end
  end

  private

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    Date.current
  end

  # Scheduled meals become quick-pick pills; every other recipe fills the
  # dropdown so the whole library is reachable without sending it to the LLM.
  def load_recipe_choices
    @scheduled_meals = Paprika::Meal
      .scheduled_between(Date.current - MEAL_WINDOW_BACK, Date.current + MEAL_WINDOW_AHEAD)
      .select { |meal| meal.recipe.present? }
    pill_recipe_ids = @scheduled_meals.map { |meal| meal.recipe.id }
    @other_recipes = Paprika::Recipe.not_trashed_excluding(pill_recipe_ids)
  end

  # Only the recipes the user explicitly picked (via pills or the dropdown) are
  # sent to the LLM, keyed by id for exact matching.
  def selected_recipes
    ids = Array(params[:recipe_ids]).map(&:to_i).select(&:positive?).uniq
    return Paprika::Recipe.none if ids.empty?

    Paprika::Recipe.where(Z_PK: ids)
  end

  # Save each parsed item as its own entry, link it to its matched recipe, and
  # standardize that recipe's stored nutrition.
  def persist_entries(entries, raw_input, recipes)
    recipes_by_id = recipes.index_by(&:id)

    entries.each do |entry|
      recipe = recipes_by_id[entry["recipe_id"]&.to_i]

      nutrition_entry = NutritionEntry.create!(
        logged_on: @date,
        raw_input: raw_input,
        item: entry["item"].to_s.presence || "Unknown item",
        calories: entry["calories"],
        protein: entry["protein"],
        carbs: entry["carbs"],
        fat: entry["fat"],
        recipe_match: recipe&.name
      )

      next unless recipe

      nutrition_entry.nutrition_entry_recipes.create!(recipe_id: recipe.id)
      write_batch_macros(recipe, entry["batch_macros"])
    end
  end

  # Overwrite the matched recipe's nutrition field with the AI's validated batch
  # macros in one canonical format, standardizing (and correcting) it on every run.
  def write_batch_macros(recipe, batch)
    return if batch.blank?

    standardized = standardized_nutrition(batch)
    return if standardized == recipe.nutritional_info

    recipe.update_nutritional_info!(standardized)
  rescue StandardError => e
    Rails.logger.warn("Failed to write batch macros for #{recipe.name}: #{e.message}")
  end

  def standardized_nutrition(batch)
    "Batch total | Calories: #{batch['calories'].to_i} kcal | " \
    "Protein: #{batch['protein'].to_i} g | Carbohydrates: #{batch['carbs'].to_i} g | " \
    "Fat: #{batch['fat'].to_i} g"
  end
end
