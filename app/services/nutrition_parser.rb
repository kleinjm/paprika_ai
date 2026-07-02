require "json"

# Turns a plain-English description of what the user ate into structured macro
# entries, seeding the LLM with the user's Paprika recipes as reference.
class NutritionParser
  Result = Struct.new(:entries, :reply, :error, keyword_init: true)

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a macro-tracking assistant for someone trying to put on muscle, so
    calories and protein are the highest priorities. The user will tell you in
    plain English what they ate. Convert it into structured macros.

    A single message may describe several foods (e.g. "small bowl bean salad
    medium plate chicken breast"). Split it into one entry per distinct food,
    and match each entry independently against the reference recipes.

    Two logging modes:
    - HOME COOKING: If they reference one of their master recipes (possibly as a
      fraction or serving, e.g. "1/4 of the chili"), work out the batch macros for
      the whole recipe, then the portion they actually ate. A recipe may include
      existing "nutritional_info":
        * VERIFIED DATA: If nutritional_info starts with the word "Verified", it
          was entered by hand from a nutrition label and the app will apply those
          numbers itself. Do NOT estimate its macros. Set "batch_macros" to null.
          Just return "recipe_fraction": the fraction of the WHOLE recipe eaten
          (e.g. 0.25 for a quarter, ~0.2 for one bowl of a five-bowl pot).
        * OTHERWISE: Treat nutritional_info as UNTRUSTED — internet recipes often
          have wrong data. Sanity-check against the ingredients; if it looks wrong
          or is missing, compute the batch macros from the ingredients. Return the
          full corrected "batch_macros" so it can be stored.
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
          "recipe_fraction": float fraction of the whole recipe eaten (home cooking) or null,
          "batch_macros": { "calories": int, "protein": int, "carbs": int, "fat": int, "fiber": int, "saturated_fat": int, "sugar": int } or null
        }
      ],
      "reply": "a short friendly confirmation of what you logged and the day's running totals"
    }

    All per-entry nutrient fields (calories in kcal; protein, carbs, fat, fiber,
    saturated_fat, sugar in grams) are for the PORTION the user actually ate.

    Only set "recipe_id" and "batch_macros" for HOME COOKING items that matched
    one of the provided reference recipes; use the recipe's exact "id". For
    anything not in the reference list, set them to null. Set "batch_macros" to
    null for Verified recipes. Round all numbers to integers.
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
      reply: "The nutrition assistant is temporarily unavailable#{detail} (the AI service may be busy). Please try again in a moment.",
      error: true
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
    Result.new(entries: [], reply: "Sorry, I couldn't read that. Please try rephrasing what you ate.", error: true)
  end
end
