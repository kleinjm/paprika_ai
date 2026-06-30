class NutritionController < ApplicationController
  def show
    @date = parse_date(params[:date])
    @entries = NutritionEntry.for_day(@date)
    @totals = NutritionEntry.totals_for(@date)
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

  def write_batch_macros(entry)
    name = entry["recipe_match"]
    batch = entry["batch_macros"]
    return if name.blank? || batch.blank?

    recipe = Paprika::Recipe.find_by(ZNAME: name)
    return if recipe.nil? || recipe.nutritional_info.present?

    recipe.update_nutritional_info!(
      "Batch total | Calories: #{batch['calories']}kcal | " \
      "Protein: #{batch['protein']}g | Carbohydrates: #{batch['carbs']}g | " \
      "Fat: #{batch['fat']}g"
    )
  rescue StandardError => e
    Rails.logger.warn("Failed to write batch macros for #{name}: #{e.message}")
  end
end
