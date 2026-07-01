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

  def history
    @days = NutritionEntry.daily_totals
  end

  def clear_day
    @date = parse_date(params[:date])
    NutritionEntry.for_day(@date).destroy_all
    @reply = "Cleared the log for #{@date.strftime('%B %-d')}."
    render_day_update
  end

  def destroy_entry
    entry = NutritionEntry.find(params[:id])
    @date = entry.logged_on
    entry.destroy
    @reply = "Removed \"#{entry.item}\"."
    render_day_update
  end

  def edit_entry
    @entry = NutritionEntry.find(params[:id])
  end

  def update_entry
    @entry = NutritionEntry.find(params[:id])

    if @entry.update(entry_params)
      redirect_to nutrition_path(date: @entry.logged_on), notice: "Entry updated."
    else
      render :edit_entry, status: :unprocessable_entity
    end
  end

  private

  def entry_params
    params.require(:nutrition_entry).permit(
      :item, :calories, :protein, :carbs, :fat, :fiber, :saturated_fat, :sugar
    )
  end

  def render_day_update
    @entries = NutritionEntry.for_day(@date)
    @totals = NutritionEntry.totals_for(@date)

    respond_to do |format|
      format.turbo_stream { render :log }
      format.html { redirect_to nutrition_path(date: @date) }
    end
  end

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
        fiber: entry["fiber"],
        saturated_fat: entry["saturated_fat"],
        sugar: entry["sugar"],
        recipe_match: recipe&.name
      )

      next unless recipe

      nutrition_entry.nutrition_entry_recipes.create!(recipe_id: recipe.id)
      write_batch_macros(recipe, entry["batch_macros"])
    end
  end

  # Overwrite the matched recipe's nutrition field with the AI's validated batch
  # macros in the current versioned format, standardizing (and backfilling) it —
  # unless the skill is in read-only mode.
  def write_batch_macros(recipe, batch)
    return unless NutritionSkill.write_enabled?
    return if batch.blank?

    standardized = NutritionSkill.format(batch)
    return if standardized == recipe.nutritional_info.to_s.strip

    recipe.update_nutritional_info!(standardized)
  rescue StandardError => e
    Rails.logger.warn("Failed to write batch macros for #{recipe.name}: #{e.message}")
  end
end
