class ChatGptService
  def initialize(api_key = ENV["OPENAI_API_KEY"])
    @client = OpenAI::Client.new(access_token: api_key)
  end

  def chat(messages)
    response = @client.chat(
      parameters: {
        model: "gpt-4-turbo-preview",
        messages: messages,
        temperature: 0.7
      }
    )
    response.dig("choices", 0, "message", "content")
  end

  def analyze_recipe(recipe)
    messages = [
      { role: "system", content: "You are a helpful cooking assistant. Analyze the recipe and provide insights." },
      { role: "user", content: "Analyze this recipe:\n\n#{recipe.to_json}" }
    ]
    chat(messages)
  end

  def suggest_substitutions(ingredient)
    messages = [
      { role: "system", content: "You are a helpful cooking assistant. Suggest ingredient substitutions." },
      { role: "user", content: "What are good substitutions for #{ingredient}?" }
    ]
    chat(messages)
  end

  def suggest_meal_plan(recipes)
    messages = [
      { role: "system", content: "You are a helpful cooking assistant. Suggest a meal plan." },
      { role: "user", content: "Suggest a meal plan using these recipes:\n\n#{recipes.map(&:to_json).join("\n")}" }
    ]
    chat(messages)
  end
end
