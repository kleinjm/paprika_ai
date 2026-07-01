class NutritionController < ApplicationController
  def show
    @date = parse_date(params[:date])
    @entries = NutritionEntry.for_day(@date)
    @totals = NutritionEntry.totals_for(@date)
    @scheduled_meals = Paprika::Meal.scheduled_between(Date.current - 7, Date.current + 2)
  end

  def log
    @date = parse_date(params[:date])
    message = params[:message].to_s.strip

    if message.blank?
      @reply = "Tell me what you ate and I'll log it."
    else
      result = NutritionParser.new.parse(message, recipes: reference_recipes)
      persist_entries(result.entries, message)
      @reply = result.reply
    end

    @entries = NutritionEntry.for_day(@date)
    @totals = NutritionEntry.totals_for(@date)

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

  def reference_recipes
    Paprika::Recipe.where(ZINTRASH: nil)
  end

  # Save each parsed item, and write computed batch macros back into the
  # matched Paprika recipe's nutrition field when it doesn't already have any.
  def persist_entries(entries, raw_input)
    entries.each do |entry|
      NutritionEntry.create!(
        logged_on: @date,
        raw_input: raw_input,
        item: entry["item"].to_s.presence || "Unknown item",
        calories: entry["calories"],
        protein: entry["protein"],
        carbs: entry["carbs"],
        fat: entry["fat"],
        recipe_match: entry["recipe_match"]
      )

      write_batch_macros(entry)
    end
  end

  # Overwrite the matched recipe's nutrition field with the AI's validated batch
  # macros in one canonical format, standardizing (and correcting) it on every run.
  def write_batch_macros(entry)
    name = entry["recipe_match"]
    batch = entry["batch_macros"]
    return if name.blank? || batch.blank?

    recipe = Paprika::Recipe.find_by(ZNAME: name)
    return if recipe.nil?

    standardized = standardized_nutrition(batch)
    return if standardized == recipe.nutritional_info

    recipe.update_nutritional_info!(standardized)
  rescue StandardError => e
    Rails.logger.warn("Failed to write batch macros for #{name}: #{e.message}")
  end

  def standardized_nutrition(batch)
    "Batch total | Calories: #{batch['calories'].to_i} kcal | " \
    "Protein: #{batch['protein'].to_i} g | Carbohydrates: #{batch['carbs'].to_i} g | " \
    "Fat: #{batch['fat'].to_i} g"
  end
end
