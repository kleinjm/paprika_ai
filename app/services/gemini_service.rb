require "gemini-ai"

class GeminiService
  # Tried in order; on a transient failure we fall through to the next model.
  # ENV["GEMINI_MODEL"], when set, is prepended as the preferred model.
  FALLBACK_MODELS = %w[
    gemini-2.5-flash-lite
    gemini-2.5-flash
    gemini-3.5-flash
  ].freeze

  # HTTP statuses worth retrying on a different model (overload/rate/server errors).
  RETRYABLE_STATUSES = [ 429, 500, 502, 503, 504 ].freeze

  def initialize(models: nil)
    @models = Array(models).map(&:to_s).reject(&:empty?)
    @models = default_models if @models.empty?
  end

  def generate_content(prompt:)
    last_error = nil

    @models.each do |model|
      return request(model, prompt)
    rescue StandardError => e
      raise unless retryable?(e)

      last_error = e
      Rails.logger.warn("GeminiService: #{model} failed (#{e.message}); trying next model") if defined?(Rails)
    end

    raise last_error
  end

  private

  def default_models
    preferred = ENV["GEMINI_MODEL"].to_s.strip
    preferred.empty? ? FALLBACK_MODELS.dup : [ preferred, *FALLBACK_MODELS ].uniq
  end

  def retryable?(error)
    code = error.message[/\b\d{3}\b/]&.to_i
    code && RETRYABLE_STATUSES.include?(code)
  end

  def request(model, prompt)
    client = Gemini.new(
      credentials: {
        service: "generative-language-api",
        api_key: Rails.application.credentials.dig(:google, :gemini, :api_key)
      },
      options: { model: model }
    )

    result = client.generate_content(
      { contents: { role: "user", parts: { text: prompt } } }
    )
    result.dig("candidates", 0, "content", "parts", 0, "text")
  end
end
