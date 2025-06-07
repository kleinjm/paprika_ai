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

  def generate_content(prompt:)
    result = @client.generate_content(
      { contents: { role: "user", parts: { text: prompt } } }
    )
    result.dig("candidates", 0, "content", "parts", 0, "text")
  end
end
