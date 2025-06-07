require "gemini-ai"

class GeminiService
  def initialize
    @client = Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV["GEMINI_API_KEY"]
      },
      options: { model: "gemini-2.0-flash" }
    )
  end

  def analyze_recipe(recipe)
    prompt = "Analyze this recipe:\n\n#{recipe.name}\n\nIngredients:\n#{recipe.ingredients}\n\nInstructions:\n#{recipe.directions}"

    result = @client.generate_content(
      { contents: { role: "user", parts: { text: prompt } } }
    )

    result.dig("candidates", 0, "content", "parts", 0, "text")
  end

  def suggest_substitutions(ingredient)
    prompt = "Suggest substitutions for #{ingredient}"

    result = @client.generate_content(
      { contents: { role: "user", parts: { text: prompt } } }
    )

    result.dig("candidates", 0, "content", "parts", 0, "text")
  end

  def suggest_meal_plan(recipes:, prompt:)
    prompt += "\n\nRecipes:\n#{recipes.map(&:name).join(", ")}"

    result = @client.generate_content(
      { contents: { role: "user", parts: { text: prompt } } }
    )

    result.dig("candidates", 0, "content", "parts", 0, "text")
  end
end
