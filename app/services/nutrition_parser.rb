require "json"

# Turns a plain-English description of what the user ate into structured macro
# entries, seeding the LLM with the user's Paprika recipes as reference.
class NutritionParser
  Result = Struct.new(:entries, :reply, keyword_init: true)

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a macro-tracking assistant for someone trying to put on muscle, so
    calories and protein are the highest priorities. The user will tell you in
    plain English what they ate. Convert it into structured macros.

    A single message may describe several foods (e.g. "small bowl bean salad
    medium plate chicken breast"). Split it into one entry per distinct food,
    and match each entry independently against the reference recipes.

    Two logging modes:
    - HOME COOKING: If they reference one of their master recipes (possibly as a
      fraction or serving, e.g. "1/4 of the chili"), compute the BATCH macros for
      the whole recipe, then work out the portion they actually ate.
      A recipe may include existing "nutritional_info". Treat it as UNTRUSTED:
      internet recipes often have wrong or mislabeled data. Sanity-check it
      against the ingredient list. If it is plausible, you may use it; if it looks
      wrong (off by a large factor, missing, or inconsistent with the
      ingredients), IGNORE it and compute the batch macros from the ingredients
      instead. Always return the full, corrected batch macros so they can be
      stored in a standardized format.
    - EATING OUT: Make a conservative, realistic estimate based on standard
      restaurant/database averages. Bracket to the closest common equivalent.

    Return ONLY valid JSON (no markdown fences) of the form:
    {
      "entries": [
        {
          "item": "short description of what was eaten",
          "calories": int, "protein": int, "carbs": int, "fat": int,
          "fiber": int, "saturated_fat": int, "sugar": int,
          "recipe_id": int (the "id" of the matched recipe from the reference list) or null,
          "batch_macros": { "calories": int, "protein": int, "carbs": int, "fat": int } or null
        }
      ],
      "reply": "a short friendly confirmation of what you logged and the day's running totals"
    }

    All per-entry nutrient fields (calories in kcal; protein, carbs, fat, fiber,
    saturated_fat, sugar in grams) are for the PORTION the user actually ate.

    Only set "recipe_id" and "batch_macros" for HOME COOKING items that matched
    one of the provided reference recipes; use the recipe's exact "id". For
    anything not in the reference list, set both to null. Round all numbers to
    integers.
  PROMPT

  def initialize(gemini: GeminiService.new)
    @gemini = gemini
  end

  def parse(message, recipes:)
    prompt = build_prompt(message, recipes)
    raw = @gemini.generate_content(prompt: prompt)
    parse_json(raw)
  rescue StandardError => e
    Rails.logger.warn("NutritionParser API error: #{e.class}: #{e.message}") if defined?(Rails)
    code = e.message[/\b\d{3}\b/]
    detail = code ? " (error #{code})" : ""
    Result.new(
      entries: [],
      reply: "The nutrition assistant is temporarily unavailable#{detail} (the AI service may be busy). Please try again in a moment."
    )
  end

  private

  def build_prompt(message, recipes)
    reference = recipes.map do |r|
      {
        id: r.id,
        name: r.name,
        nutritional_info: r.nutritional_info.presence,
        ingredients: r.ingredients
      }
    end

    reference_section =
      if reference.any?
        "Here are the reference recipes the user may be describing (JSON):\n#{reference.to_json}"
      else
        "No specific reference recipes were provided; treat everything as EATING OUT."
      end

    <<~TEXT
      #{SYSTEM_PROMPT}

      #{reference_section}

      The user ate:
      #{message}
    TEXT
  end

  def parse_json(raw)
    json = raw.to_s.strip.sub(/\A```(?:json)?/, "").sub(/```\z/, "").strip
    # Tolerate trailing commas the model sometimes emits before a closing } or ].
    json = json.gsub(/,(\s*[}\]])/, '\1')
    data = JSON.parse(json)
    Result.new(
      entries: Array(data["entries"]),
      reply: data["reply"].presence || "Logged."
    )
  rescue JSON::ParserError
    Result.new(entries: [], reply: "Sorry, I couldn't read that. Please try rephrasing what you ate.")
  end
end
