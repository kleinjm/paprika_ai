require "rails_helper"

RSpec.describe "Nutrition", type: :request do
  # Keep the specs off the read-only Paprika SQLite DB by stubbing the Paprika
  # query methods the controller uses, while letting the real controller logic run.
  def stub_paprika(scheduled_meals: [], other_recipes: [])
    allow(Paprika::Meal).to receive(:scheduled_between).and_return(scheduled_meals)
    allow(Paprika::Recipe).to receive(:not_trashed_excluding).and_return(other_recipes)
  end

  before { stub_paprika }

  describe "GET /nutrition" do
    it "renders the tracking page for today" do
      get nutrition_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nutrition Tracking")
    end

    it "renders a clickable pill (with recipe id) only for meals that have a recipe" do
      with_recipe = double("Meal", title: "Instant Pot Stuffed Pepper Soup", recipe: double(id: 521))
      without_recipe = double("Meal", title: "Freeform note", recipe: nil)
      stub_paprika(scheduled_meals: [ with_recipe, without_recipe ])

      get nutrition_path

      expect(response.body).to include("Instant Pot Stuffed Pepper Soup")
      expect(response.body).to include("meal-picker#fill")
      expect(response.body).to include("521")
      expect(response.body).not_to include("Freeform note")
    end

    it "renders a dropdown option for each other recipe" do
      stub_paprika(other_recipes: [ double(id: 7, name: "Zuppa Toscana") ])

      get nutrition_path

      expect(response.body).to include("Zuppa Toscana")
      expect(response.body).to include("meal-picker#pick")
    end
  end

  describe "POST /nutrition/log" do
    let(:result) do
      NutritionParser::Result.new(
        entries: [
          { "item" => "banana", "calories" => 100, "protein" => 1, "carbs" => 27, "fat" => 0,
            "recipe_id" => nil, "batch_macros" => nil }
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
      expect(entry.nutrition_entry_recipes).to be_empty
    end

    it "does not call the parser or create entries for a blank message" do
      expect(NutritionParser).not_to receive(:new)

      expect do
        post nutrition_log_path, params: { message: "   " }, as: :turbo_stream
      end.not_to change(NutritionEntry, :count)

      expect(response.body).to include("Tell me what you ate")
    end

    context "deleting entries" do
      let!(:entry) { NutritionEntry.create!(logged_on: Date.new(2026, 6, 29), item: "banana", calories: 100) }
      let!(:other) { NutritionEntry.create!(logged_on: Date.new(2026, 6, 29), item: "eggs", calories: 150) }

      it "removes a single entry and responds with a turbo stream" do
        expect do
          delete nutrition_entry_path(entry), as: :turbo_stream
        end.to change(NutritionEntry, :count).by(-1)

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(NutritionEntry.exists?(entry.id)).to be(false)
        expect(response.body).to include("Removed")
      end

      it "clears all entries for the day" do
        expect do
          delete nutrition_clear_path(date: "2026-06-29"), as: :turbo_stream
        end.to change(NutritionEntry, :count).by(-2)

        expect(response.body).to include("Cleared the log")
      end

      it "redirects for an HTML request" do
        delete nutrition_entry_path(entry)
        expect(response).to redirect_to(nutrition_path(date: Date.new(2026, 6, 29)))
      end
    end

    context "when items match selected recipes" do
      let(:chili) do
        instance_double(Paprika::Recipe, id: 42, name: "Chili", nutritional_info: "Calories: 999")
      end
      let(:salad) do
        instance_double(Paprika::Recipe, id: 7, name: "Bean Salad", nutritional_info: nil)
      end
      let(:result) do
        NutritionParser::Result.new(
          entries: [
            { "item" => "medium bowl chili", "calories" => 600, "protein" => 45, "carbs" => 30, "fat" => 20,
              "fiber" => 12, "saturated_fat" => 6, "sugar" => 5,
              "recipe_id" => 42,
              "batch_macros" => { "calories" => 2400, "protein" => 180, "carbs" => 120, "fat" => 80 } },
            { "item" => "small bowl bean salad", "calories" => 200, "protein" => 8, "carbs" => 25, "fat" => 6,
              "recipe_id" => 7,
              "batch_macros" => { "calories" => 800, "protein" => 32, "carbs" => 100, "fat" => 24 } }
          ],
          reply: "Logged both."
        )
      end

      before do
        allow(Paprika::Recipe).to receive(:where).with(Z_PK: [ 42, 7 ]).and_return([ chili, salad ])
        allow(chili).to receive(:update_nutritional_info!)
        allow(salad).to receive(:update_nutritional_info!)
      end

      it "creates one entry per item, each linked to its recipe" do
        expect do
          post nutrition_log_path, params: { message: "medium bowl chili small bowl bean salad", recipe_ids: [ 42, 7 ] },
                                   as: :turbo_stream
        end.to change(NutritionEntry, :count).by(2)
          .and change(NutritionEntryRecipe, :count).by(2)

        chili_entry = NutritionEntry.find_by(item: "medium bowl chili")
        expect(chili_entry.recipe_match).to eq("Chili")
        expect(chili_entry.fiber).to eq(12)
        expect(chili_entry.saturated_fat).to eq(6)
        expect(chili_entry.sugar).to eq(5)
        expect(chili_entry.nutrition_entry_recipes.pluck(:recipe_id)).to eq([ 42 ])
      end

      it "standardizes each matched recipe's nutrition" do
        expect(chili).to receive(:update_nutritional_info!).with(
          "Meal Total (AI Generated - 7/1/26)\nCalories: 2400 kcal\nProtein: 180 g\nCarbohydrates: 120 g\nFat: 80 g"
        )
        expect(salad).to receive(:update_nutritional_info!).with(
          "Meal Total (AI Generated - 7/1/26)\nCalories: 800 kcal\nProtein: 32 g\nCarbohydrates: 100 g\nFat: 24 g"
        )

        post nutrition_log_path, params: { message: "chili and salad", recipe_ids: [ 42, 7 ] },
                                 as: :turbo_stream
      end

      it "does not write to recipes in read-only mode" do
        allow(NutritionSkill).to receive(:write_enabled?).and_return(false)
        expect(chili).not_to receive(:update_nutritional_info!)
        expect(salad).not_to receive(:update_nutritional_info!)

        post nutrition_log_path, params: { message: "chili and salad", recipe_ids: [ 42, 7 ] },
                                 as: :turbo_stream
      end

      it "still logs the entry when writing back to Paprika fails" do
        allow(chili).to receive(:update_nutritional_info!).and_raise(StandardError, "db locked")
        allow(salad).to receive(:update_nutritional_info!)
        allow(Rails.logger).to receive(:warn)

        expect do
          post nutrition_log_path, params: { message: "chili and salad", recipe_ids: [ 42, 7 ] },
                                   as: :turbo_stream
        end.to change(NutritionEntry, :count).by(2)

        expect(Rails.logger).to have_received(:warn).with(/Failed to write batch macros for Chili/)
      end
    end
  end
end
