require "rails_helper"

RSpec.describe "Nutrition", type: :request do
  before do
    # Avoid touching the real Paprika SQLite database in tests.
    allow(Paprika::Recipe).to receive(:where).and_return([])
    allow(Paprika::Meal).to receive(:scheduled_between).and_return([])
  end

  describe "GET /nutrition" do
    it "renders the tracking page for today" do
      get nutrition_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nutrition Tracking")
    end

    it "renders a clickable pill for each scheduled meal" do
      meal = double("Meal", title: "Instant Pot Stuffed Pepper Soup")
      allow(Paprika::Meal).to receive(:scheduled_between).and_return([meal])

      get nutrition_path

      expect(response.body).to include("Instant Pot Stuffed Pepper Soup")
      expect(response.body).to include("meal-picker#fill")
    end
  end

  describe "POST /nutrition/log" do
    let(:result) do
      NutritionParser::Result.new(
        entries: [
          { "item" => "banana", "calories" => 100, "protein" => 1, "carbs" => 27, "fat" => 0,
            "recipe_match" => nil, "batch_macros" => nil }
        ],
        reply: "Logged a banana."
      )
    end

    before do
      parser = instance_double(NutritionParser, parse: result)
      allow(NutritionParser).to receive(:new).and_return(parser)
    end

    it "persists the parsed entries and responds with a turbo stream" do
      expect do
        post nutrition_log_path, params: { message: "a banana", date: "2026-06-29" },
                                 as: :turbo_stream
      end.to change(NutritionEntry, :count).by(1)

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("nutrition_totals")
      expect(response.body).to include("Logged a banana.")

      entry = NutritionEntry.last
      expect(entry.item).to eq("banana")
      expect(entry.logged_on).to eq(Date.new(2026, 6, 29))
    end

    it "does not call the parser or create entries for a blank message" do
      expect(NutritionParser).not_to receive(:new)

      expect do
        post nutrition_log_path, params: { message: "   " }, as: :turbo_stream
      end.not_to change(NutritionEntry, :count)

      expect(response.body).to include("Tell me what you ate")
    end

    context "when an entry matches a recipe with existing nutrition info" do
      let(:recipe) { instance_double(Paprika::Recipe, nutritional_info: "Calories: 999") }
      let(:result) do
        NutritionParser::Result.new(
          entries: [
            { "item" => "1/4 chili", "calories" => 600, "protein" => 45, "carbs" => 30, "fat" => 20,
              "recipe_match" => "Chili",
              "batch_macros" => { "calories" => 2400, "protein" => 180, "carbs" => 120, "fat" => 80 } }
          ],
          reply: "Logged it."
        )
      end

      it "overwrites the recipe nutrition with the standardized batch macros" do
        allow(Paprika::Recipe).to receive(:find_by).with(ZNAME: "Chili").and_return(recipe)

        expect(recipe).to receive(:update_nutritional_info!).with(
          "Batch total | Calories: 2400 kcal | Protein: 180 g | Carbohydrates: 120 g | Fat: 80 g"
        )

        post nutrition_log_path, params: { message: "1/4 chili" }, as: :turbo_stream
      end
    end
  end
end
