# frozen_string_literal: true

# Rewrites a recipe's directions into James's terse cooking shorthand, using the
# Gemini model. The notation rules are the same ones the `recipe-shorthand`
# Claude skill uses — read from that skill's reference doc so the app and the
# skill share a single source of truth for the syntax.
class RecipeShorthand
  SYNTAX_DOC = Rails.root.join(".claude/skills/recipe-shorthand/references/shorthand-syntax.md")

  def initialize(ai: GeminiService.new)
    @ai = ai
  end

  # Returns the rewritten directions as a plain string.
  def rewrite(recipe)
    @ai.generate_content(prompt: prompt_for(recipe)).to_s.strip
  end

  private

  def prompt_for(recipe)
    <<~PROMPT
      You rewrite recipe directions into a terse cooking shorthand. Follow the
      syntax rules below exactly.

      #{syntax_rules}

      ---

      Rewrite the DIRECTIONS of the following recipe into the shorthand. Use the
      INGREDIENTS list to spell out every ingredient by its full name — never
      abbreviate an ingredient to a category ("all veggies", "sauce", "herbs")
      and never shorten a full name ("sweet potatoes, Yukon gold potatoes" stays
      that way even in a later step).

      Output ONLY the rewritten directions — no preamble, no explanation, no code
      fences.

      RECIPE: #{recipe.name}

      INGREDIENTS:
      #{recipe.ingredients}

      DIRECTIONS:
      #{recipe.directions}
    PROMPT
  end

  def syntax_rules
    File.read(SYNTAX_DOC)
  end
end
