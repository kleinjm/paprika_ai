require "rails_helper"

RSpec.describe RecipeShorthand do
  let(:ai) { instance_double(GeminiService) }
  subject(:shorthand) { described_class.new(ai: ai) }

  let(:recipe) do
    double("Recipe", name: "Chili", ingredients: "beans\nground beef", directions: "Cook it all.")
  end

  it "prompts Gemini with the syntax rules, ingredients and directions, and trims the output" do
    captured = nil
    allow(ai).to receive(:generate_content) do |prompt:|
      captured = prompt
      "  brown beef + beans -> simmer  "
    end

    expect(shorthand.rewrite(recipe)).to eq("brown beef + beans -> simmer")
    expect(captured).to include("terse cooking shorthand")
    expect(captured).to include("Chili")
    expect(captured).to include("ground beef")
    expect(captured).to include("Cook it all.")
    # The syntax rules are read from the shared skill reference doc.
    expect(captured).to include(File.read(RecipeShorthand::SYNTAX_DOC).strip.lines.first.strip)
  end
end
