require "spec_helper"
require_relative "../../app/services/gemini_service"

RSpec.describe GeminiService do
  let(:client) { double("Gemini::Client") }

  def stub_model(model, client)
    allow(Gemini).to receive(:new)
      .with(hash_including(options: { model: model }))
      .and_return(client)
  end

  def candidates(text)
    { "candidates" => [ { "content" => { "parts" => [ { "text" => text } ] } } ] }
  end

  before { allow(Gemini).to receive(:new).and_return(client) }

  describe "#generate_content" do
    it "passes the prompt through and returns the first candidate's text" do
      expect(client).to receive(:generate_content)
        .with({ contents: { role: "user", parts: { text: "hi" } } })
        .and_return(candidates("hello back"))

      expect(described_class.new.generate_content(prompt: "hi")).to eq("hello back")
    end

    it "returns nil when the response has no candidates" do
      allow(client).to receive(:generate_content).and_return({})
      expect(described_class.new.generate_content(prompt: "anything")).to be_nil
    end

    it "falls through to the next model on a transient (503) error" do
      overloaded = double("Overloaded")
      healthy = double("Healthy")
      allow(overloaded).to receive(:generate_content).and_raise(StandardError, "the server responded with status 503")
      allow(healthy).to receive(:generate_content).and_return(candidates("recovered"))

      stub_model("gemini-2.5-flash-lite", overloaded)
      stub_model("gemini-2.5-flash", healthy)

      service = described_class.new(models: %w[gemini-2.5-flash-lite gemini-2.5-flash])
      expect(service.generate_content(prompt: "hi")).to eq("recovered")
    end

    it "does not cycle on a non-retryable (400) error" do
      bad = double("Bad")
      allow(bad).to receive(:generate_content).and_raise(StandardError, "status 400 invalid")
      stub_model("gemini-2.5-flash-lite", bad)

      service = described_class.new(models: %w[gemini-2.5-flash-lite gemini-2.5-flash])
      expect { service.generate_content(prompt: "hi") }.to raise_error(/400/)
    end

    it "re-raises the last error when every model is exhausted" do
      down = double("Down")
      allow(down).to receive(:generate_content).and_raise(StandardError, "status 503")
      stub_model("gemini-2.5-flash-lite", down)
      stub_model("gemini-2.5-flash", down)

      service = described_class.new(models: %w[gemini-2.5-flash-lite gemini-2.5-flash])
      expect { service.generate_content(prompt: "hi") }.to raise_error(/503/)
    end

    it "prefers ENV['GEMINI_MODEL'] when no models are given" do
      preferred = double("Preferred")
      allow(preferred).to receive(:generate_content).and_return(candidates("from env"))
      stub_model("gemini-custom-model", preferred)

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GEMINI_MODEL").and_return("gemini-custom-model")

      expect(described_class.new.generate_content(prompt: "hi")).to eq("from env")
    end
  end
end
