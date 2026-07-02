class NutritionController < ApplicationController
  MEAL_WINDOW_BACK = 7
  MEAL_WINDOW_AHEAD = 2

  def show
    @date = parse_date(params[:date])
    @entries = entries.for_day(@date)
    @totals = entries.totals_for(@date)
    @goals = current_user.settings
    load_recipe_choices
  end

  def log
    @date = parse_date(params[:date])
    message = params[:message].to_s.strip

    recipes = selected_recipes
    direct = direct_log_entries(message, recipes)

    if direct
      # Just recipe pills with locally-known nutrition — log straight from the
      # stored data without calling the LLM.
      persist_direct(direct, message)
      @reply = "Logged #{direct.map { |recipe, _| recipe.name }.join(', ')} from saved nutrition."
    elsif message.blank?
      @reply = "Tell me what you ate and I'll log it."
    else
      result = NutritionParser.new.parse(message, recipes: recipes)
      persist_entries(result.entries, message, recipes)
      @reply = result.reply
      needs = incomplete_verified_recipes(result.entries, recipes)
      @reply += "\n\nThese recipes need more nutrition data: #{needs.join(', ')}." if needs.any?
      @llm_error = result.error
    end

    @entries = entries.for_day(@date)
    @totals = entries.totals_for(@date)
    @goals = current_user.settings
    load_recipe_choices

    respond_to do |format|
      # A 422 on error means Turbo still renders the streams, but the form's
      # reset/clear (guarded on submit success) is skipped, preserving the input.
      format.turbo_stream { render :log, status: @llm_error ? :unprocessable_entity : :ok }
      format.html { redirect_to nutrition_path(date: @date) }
    end
  end

  def history
    @days = entries.daily_totals
    @goals = current_user.settings
  end

  def clear_day
    @date = parse_date(params[:date])
    entries.for_day(@date).destroy_all
    @reply = "Cleared the log for #{@date.strftime('%B %-d')}."
    render_day_update
  end

  def destroy_entry
    entry = entries.find(params[:id])
    @date = entry.logged_on
    entry.destroy
    @reply = "Removed \"#{entry.item}\"."
    render_day_update
  end

  def edit_entry
    @entry = entries.find(params[:id])
  end

  def update_entry
    @entry = entries.find(params[:id])

    if @entry.update(entry_params)
      redirect_to nutrition_path(date: @entry.logged_on), notice: "Entry updated."
    else
      render :edit_entry, status: :unprocessable_entity
    end
  end

  private

  def entries
    current_user.nutrition_entries
  end

  def entry_params
    params.require(:nutrition_entry).permit(
      :item, :calories, :protein, :carbs, :fat, :fiber, :saturated_fat, :sugar
    )
  end

  def render_day_update
    @entries = entries.for_day(@date)
    @totals = entries.totals_for(@date)
    @goals = current_user.settings

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
    staple_ids = current_user.user_staple_recipes.pluck(:recipe_id)
    # Staples become their own pill row, deduped against the meal pills.
    @staple_recipes = Paprika::Recipe.not_trashed_in(staple_ids - pill_recipe_ids)
    # The dropdown holds everything not already reachable as a pill.
    @other_recipes = Paprika::Recipe.not_trashed_excluding(pill_recipe_ids + staple_ids)
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
  def persist_entries(parsed_entries, raw_input, recipes)
    recipes_by_id = recipes.index_by(&:id)

    parsed_entries.each do |entry|
      recipe = recipes_by_id[entry["recipe_id"]&.to_i]
      macros = verified_portion(recipe, entry) || entry

      nutrition_entry = entries.create!(
        logged_on: @date,
        raw_input: raw_input,
        item: entry["item"].to_s.presence || "Unknown item",
        calories: macros["calories"],
        protein: macros["protein"],
        carbs: macros["carbs"],
        fat: macros["fat"],
        fiber: macros["fiber"],
        saturated_fat: macros["saturated_fat"],
        sugar: macros["sugar"],
        recipe_match: recipe&.name
      )

      next unless recipe

      nutrition_entry.nutrition_entry_recipes.create!(recipe_id: recipe.id)
      write_batch_macros(recipe, entry["batch_macros"])
    end
  end

  # When the matched recipe has hand-Verified nutrition, compute the eaten
  # portion deterministically from the label (LLM only supplies the fraction).
  def verified_portion(recipe, entry)
    return nil unless recipe && VerifiedNutrition.verified?(recipe.nutritional_info)

    fraction = entry["recipe_fraction"]
    return nil if fraction.blank?

    label = VerifiedNutrition.parse(recipe.nutritional_info)
    VerifiedNutrition::NUTRIENTS.to_h do |nutrient|
      value = label[nutrient]
      [ nutrient.to_s, value && (value * fraction.to_f).round ]
    end
  end

  # Names of referenced Verified recipes that are missing some nutrients.
  def incomplete_verified_recipes(parsed_entries, recipes)
    recipes_by_id = recipes.index_by(&:id)
    ids = parsed_entries.filter_map { |entry| entry["recipe_id"]&.to_i }.uniq
    ids.filter_map do |id|
      recipe = recipes_by_id[id]
      next unless recipe && VerifiedNutrition.verified?(recipe.nutritional_info)

      recipe.name if VerifiedNutrition.missing(recipe.nutritional_info).any?
    end
  end

  # If the message is only recipe pill names (no extra text) and every selected
  # recipe already has locally-known nutrition (Verified or AI Generated), return
  # [recipe, nutrients] pairs so we can log without the LLM. Otherwise nil.
  def direct_log_entries(message, recipes)
    return nil if recipes.none? || !only_recipe_names?(message, recipes)

    pairs = recipes.map { |recipe| [ recipe, local_nutrition(recipe) ] }
    pairs unless pairs.any? { |_recipe, nutrients| nutrients.nil? }
  end

  def only_recipe_names?(message, recipes)
    leftover = message.to_s.dup
    recipes.each { |recipe| leftover = leftover.sub(/#{Regexp.escape(recipe.name)}/i, "") }
    leftover.gsub(/[^a-z0-9]/i, "").blank?
  end

  # Parsed nutrients for a recipe whose field is Verified or AI-Generated, else nil.
  def local_nutrition(recipe)
    info = recipe.nutritional_info.to_s
    return nil unless VerifiedNutrition.verified?(info) || info.strip.start_with?(NutritionSkill::HEADER_PREFIX)

    VerifiedNutrition.parse(info)
  end

  def persist_direct(pairs, raw_input)
    pairs.each do |recipe, nutrients|
      entry = entries.create!(
        logged_on: @date,
        raw_input: raw_input,
        item: recipe.name,
        calories: nutrients[:calories]&.round,
        protein: nutrients[:protein]&.round,
        carbs: nutrients[:carbs]&.round,
        fat: nutrients[:fat]&.round,
        fiber: nutrients[:fiber]&.round,
        saturated_fat: nutrients[:saturated_fat]&.round,
        sugar: nutrients[:sugar]&.round,
        recipe_match: recipe.name
      )
      entry.nutrition_entry_recipes.create!(recipe_id: recipe.id)
    end
  end

  # Overwrite the matched recipe's nutrition field with the AI's validated batch
  # macros in the current versioned format, standardizing (and backfilling) it —
  # unless the skill is read-only or the recipe is hand-Verified (never touched).
  def write_batch_macros(recipe, batch)
    return unless NutritionSkill.write_enabled?
    return if VerifiedNutrition.verified?(recipe.nutritional_info)
    return if batch.blank?

    standardized = NutritionSkill.format(batch)
    return if standardized == recipe.nutritional_info.to_s.strip

    recipe.update_nutritional_info!(standardized)
  rescue StandardError => e
    Rails.logger.warn("Failed to write batch macros for #{recipe.name}: #{e.message}")
  end
end
