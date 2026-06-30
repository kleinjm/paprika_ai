require "spec_helper"
require "active_model"
require "json"

module Paprika
  class Recipe
    def self.all = @all ||= []
    def self.reset!(records) = @all = records
    def self.joins(*) = RelationStub.new(@all || [])
  end

  class RelationStub
    def initialize(records) = @records = records
    def where(*) = self
    def distinct = @records
  end
end

require_relative "../../app/forms/meal_plan_form"

RSpec.describe MealPlanForm do
  let(:recipe) { double("Recipe", to_ai_json: { id: 1, name: "Chili" }) }

  before { Paprika::Recipe.reset!([recipe]) }

  describe "defaults" do
    it "uses the default prompt and 4 recipes when nothing is passed" do
      form = described_class.new
      expect(form.prompt).to eq(described_class::DEFAULT_PROMPT)
      expect(form.num_recipes).to eq(4)
    end

    it "respects an explicit prompt and num_recipes" do
      form = described_class.new(prompt: "Custom prompt", num_recipes: 7)
      expect(form.prompt).to eq("Custom prompt")
      expect(form.num_recipes).to eq(7)
    end
  end

  describe "validations" do
    it "rejects non-positive num_recipes" do
      form = described_class.new(num_recipes: 0)
      expect(form).not_to be_valid
      expect(form.errors[:num_recipes]).not_to be_empty
    end

    it "allows nil num_recipes" do
      form = described_class.new(num_recipes: nil)
      form.num_recipes = nil
      expect(form).to be_valid
    end
  end

  describe "#build_prompt" do
    it "includes the recipe pool as JSON and the EXACT count when num_recipes is set" do
      form = described_class.new(prompt: "Plan it", num_recipes: 3)
      result = form.build_prompt
      expect(result).to include("Plan it")
      expect(result).to include("Select EXACTLY 3 recipes")
      expect(result).to include({ id: 1, name: "Chili" }.to_json)
      expect(result).to include("grouped under the day they are to be cooked")
    end

    it "falls back to the default prompt when prompt is blank" do
      form = described_class.new(prompt: "", num_recipes: 2)
      expect(form.build_prompt).to include(described_class::DEFAULT_PROMPT)
    end

    it "uses the open-ended phrasing when num_recipes is blank" do
      form = described_class.new(prompt: "Open plan", num_recipes: nil)
      form.num_recipes = nil
      result = form.build_prompt
      expect(result).to include("Open plan")
      expect(result).to include("Return the IDs of the recipes you selected")
      expect(result).not_to include("Select EXACTLY")
    end

    it "filters recipes by category_ids when provided" do
      other = double("Recipe", to_ai_json: { id: 2, name: "Tacos" })
      relation = Paprika::RelationStub.new([other])
      allow(Paprika::Recipe).to receive(:joins).and_return(relation)
      allow(relation).to receive(:where).and_return(relation)

      form = described_class.new(category_ids: [42], num_recipes: 1)
      result = form.build_prompt
      expect(result).to include({ id: 2, name: "Tacos" }.to_json)
    end
  end
end
