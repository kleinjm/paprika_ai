require "rails_helper"

RSpec.describe PaprikaCloud do
  let(:paprika_client) { instance_double(PaprikaClient::Client) }

  before do
    allow(Rails.application.credentials)
      .to receive(:paprika).and_return({ email: "you@example.com", password: "secret" })
  end

  describe ".client" do
    it "builds a PaprikaClient::Client from credentials" do
      expect(PaprikaClient::Client).to receive(:new)
        .with(email: "you@example.com", password: "secret")
        .and_return(paprika_client)

      expect(described_class.client).to eq(paprika_client)
    end

    it "raises when credentials are missing" do
      allow(Rails.application.credentials).to receive(:paprika).and_return(nil)

      expect { described_class.client }.to raise_error(/Missing Paprika credentials/)
    end
  end

  describe ".push_nutritional_info" do
    it "fetches the recipe, updates nutritional_info, and saves it" do
      recipe = PaprikaClient::Recipe.new("uid" => "ABC", "nutritional_info" => "old")
      allow(PaprikaClient::Client).to receive(:new).and_return(paprika_client)
      expect(paprika_client).to receive(:recipe).with("ABC").and_return(recipe)
      expect(paprika_client).to receive(:save_recipe).with(recipe)

      described_class.push_nutritional_info(uid: "ABC", text: "Calories: 200 calories")

      expect(recipe.nutritional_info).to eq("Calories: 200 calories")
    end
  end
end
