require "spec_helper"
require_relative "../../app/services/gemini_service"

RSpec.describe GeminiService do
  let(:client) { double("Gemini::Client") }

  before { allow(Gemini).to receive(:new).and_return(client) }

  describe "#generate_content" do
    it "passes the prompt through and returns the first candidate's text" do
      expect(client).to receive(:generate_content)
        .with({ contents: { role: "user", parts: { text: "hi" } } })
        .and_return({
          "candidates" => [
            { "content" => { "parts" => [{ "text" => "hello back" }] } }
          ]
        })

      expect(described_class.new.generate_content(prompt: "hi")).to eq("hello back")
    end

    it "returns nil when the response has no candidates" do
      allow(client).to receive(:generate_content).and_return({})
      expect(described_class.new.generate_content(prompt: "anything")).to be_nil
    end
  end
end
