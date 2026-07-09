require "spec_helper"
require "active_support/core_ext/object/blank"
require_relative "../../app/services/nutrition_parser"

RSpec.describe NutritionParser do
  let(:gemini) { double("GeminiService") }
  let(:recipe) do
    double("Recipe", id: 42, name: "Chili", servings: "Serves 4", nutritional_info: nil, ingredients: "beans, beef")
  end

  describe "#parse" do
    it "builds a prompt seeded with the reference recipes (with ids) and the message" do
      captured = nil
      allow(gemini).to receive(:generate_content) do |prompt:, **|
        captured = prompt
        %({"entries":[],"reply":"ok"})
      end

      described_class.new(gemini: gemini).parse("1/4 of the chili", recipes: [recipe])

      expect(captured).to include("macro-tracking assistant")
      expect(captured).to include("Chili")
      expect(captured).to include("beans, beef")
      expect(captured).to include(%("id":42))
      expect(captured).to include("Serves 4") # servings passed so the LLM can anchor portions
      expect(captured).to include("1/4 of the chili")
    end

    it "notes when no reference recipes were provided" do
      captured = nil
      allow(gemini).to receive(:generate_content) do |prompt:, **|
        captured = prompt
        %({"entries":[],"reply":"ok"})
      end

      described_class.new(gemini: gemini).parse("slice of pizza", recipes: [])

      expect(captured).to include("No specific reference recipes")
    end

    it "returns structured entries and the reply from valid JSON" do
      allow(gemini).to receive(:generate_content).and_return(
        %({"entries":[{"item":"1/4 chili","calories":600,"protein":45,) +
        %("carbs":30,"fat":20,"recipe_id":42,) +
        %("batch_macros":{"calories":2400,"protein":180,"carbs":120,"fat":80}}],) +
        %("reply":"Logged it."})
      )

      result = described_class.new(gemini: gemini).parse("1/4 chili", recipes: [recipe])

      expect(result.reply).to eq("Logged it.")
      expect(result.entries.size).to eq(1)
      expect(result.entries.first).to include(
        "item" => "1/4 chili", "calories" => 600, "recipe_id" => 42
      )
    end

    it "strips markdown code fences before parsing" do
      allow(gemini).to receive(:generate_content).and_return(
        %(```json\n{"entries":[],"reply":"fenced"}\n```)
      )

      result = described_class.new(gemini: gemini).parse("x", recipes: [])
      expect(result.reply).to eq("fenced")
    end

    it "tolerates trailing commas in the model's JSON" do
      allow(gemini).to receive(:generate_content).and_return(
        %({"entries":[{"item":"eggs","calories":150,"batch_macros":null,},],"reply":"ok",})
      )

      result = described_class.new(gemini: gemini).parse("eggs", recipes: [])
      expect(result.entries.size).to eq(1)
      expect(result.entries.first["item"]).to eq("eggs")
      expect(result.reply).to eq("ok")
    end

    it "returns a friendly message when the JSON is unparseable" do
      allow(gemini).to receive(:generate_content).and_return("not json at all")

      result = described_class.new(gemini: gemini).parse("x", recipes: [])
      expect(result.entries).to eq([])
      expect(result.reply).to include("couldn't read that")
      expect(result.error).to be(true)
    end

    it "defaults the reply when JSON omits it" do
      allow(gemini).to receive(:generate_content).and_return(%({"entries":[]}))

      result = described_class.new(gemini: gemini).parse("x", recipes: [])
      expect(result.reply).to eq("Logged.")
      expect(result.error).to be_falsey
    end

    it "returns a friendly message including the error code when the AI service raises" do
      allow(gemini).to receive(:generate_content).and_raise(StandardError, "the server responded with status 503")

      result = described_class.new(gemini: gemini).parse("x", recipes: [])
      expect(result.entries).to eq([])
      expect(result.reply).to include("temporarily unavailable")
      expect(result.reply).to include("error 503")
      expect(result.error).to be(true)
    end

    it "omits the code when the error has no status number" do
      allow(gemini).to receive(:generate_content).and_raise(StandardError, "connection reset")

      result = described_class.new(gemini: gemini).parse("x", recipes: [])
      expect(result.reply).to include("temporarily unavailable")
      expect(result.reply).not_to match(/error \d/)
    end
  end
end
