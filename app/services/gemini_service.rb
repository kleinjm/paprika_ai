require "gemini-ai"

class GeminiService
  def initialize
    @client = Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: ENV["GEMINI_API_KEY"]
      },
      options: { model: "gemini-pro" }
    )
  end

  def analyze_recipe(recipe)
    prompt = "Analyze this recipe:\n\n#{recipe.name}\n\nIngredients:\n#{recipe.ingredients}\n\nInstructions:\n#{recipe.directions}"

    response = @client.generate_content(prompt)

    response.dig("candidates", 0, "content", "parts", 0, "text")
  end
end
