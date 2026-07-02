require "rails_helper"

RSpec.describe "Home", type: :request do
  let(:user) { User.create!(email: "home@example.com", password: "password") }
  let(:gemini) { instance_double(GeminiService, generate_content: "AI result") }

  before do
    sign_in user
    allow(GeminiService).to receive(:new).and_return(gemini)
  end

  it "shows the login form at the root when signed out" do
    sign_out user
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("user[password]")
  end

  describe "section pages" do
    it "renders the home dashboard" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the recipe analysis page" do
      allow(Paprika::Recipe).to receive(:all).and_return([])
      get recipe_analysis_home_index_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the substitutions page" do
      get substitutions_home_index_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the meal planning page" do
      allow(Paprika::RecipeCategory).to receive(:all).and_return(Paprika::RecipeCategory.none)
      get meal_planning_home_index_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "AI actions" do
    it "analyzes a recipe" do
      recipe = double("Recipe", name: "Chili", ingredients: "beans", directions: "cook")
      allow(Paprika::Recipe).to receive(:find).with("42").and_return(recipe)

      post analyze_recipe_home_index_path, params: { id: 42 }, as: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("AI result")
    end

    it "suggests substitutions" do
      post suggest_substitutions_home_index_path,
           params: { substitution: { ingredient: "butter" } }, as: :turbo_stream

      expect(response.body).to include("AI result")
    end

    it "suggests a meal plan" do
      allow(Paprika::Recipe).to receive(:all).and_return([])

      post suggest_meal_plan_home_index_path,
           params: { meal_plan_form: { prompt: "Plan it", num_recipes: 2 } }, as: :turbo_stream

      expect(response.body).to include("AI result")
    end

    it "previews the meal plan prompt" do
      allow(Paprika::Recipe).to receive(:all).and_return([])

      post meal_plan_prompt_preview_home_index_path,
           params: { meal_plan_form: { prompt: "Plan it", num_recipes: 2 } }, as: :turbo_stream

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
