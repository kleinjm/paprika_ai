require "rails_helper"

RSpec.describe "Nutrition", type: :request do
  # Keep the specs off the read-only Paprika SQLite DB by stubbing the Paprika
  # query methods the controller uses, while letting the real controller logic run.
  def stub_paprika(scheduled_meals: [], other_recipes: [], staple_recipes: [])
    allow(Paprika::Meal).to receive(:scheduled_between).and_return(scheduled_meals)
    allow(Paprika::Recipe).to receive(:not_trashed_excluding).and_return(other_recipes)
    allow(Paprika::Recipe).to receive(:not_trashed_in).and_return(staple_recipes)
  end

  let(:user) { User.create!(email: "test@example.com", password: "password") }

  before do
    stub_paprika
    sign_in user
    allow(GeminiService).to receive(:configured?).and_return(true)
  end

  describe "authentication" do
    it "redirects to the login page when signed out" do
      sign_out user
      get nutrition_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /nutrition" do
    it "renders the tracking page for today" do
      get nutrition_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nutrition Tracking")
    end

    it "shows an error and disables the form when no API key is configured" do
      allow(GeminiService).to receive(:configured?).and_return(false)

      get nutrition_path

      expect(response.body).to include("no Gemini API key is configured")
      expect(response.body).to include("<fieldset disabled")
    end

    it "renders a clickable pill (with recipe id) only for meals that have a recipe" do
      with_recipe = double("Meal", title: "Instant Pot Stuffed Pepper Soup", recipe: double(id: 521, servings: "8 servings"))
      without_recipe = double("Meal", title: "Freeform note", recipe: nil)
      stub_paprika(scheduled_meals: [ with_recipe, without_recipe ])

      get nutrition_path

      expect(response.body).to include("Instant Pot Stuffed Pepper Soup")
      expect(response.body).to include("meal-picker#fill")
      expect(response.body).to include("521")
      expect(response.body).not_to include("Freeform note")
    end

    it "shows the serving count divider on a pill when the recipe has servings" do
      with_servings = double("Meal", title: "Granola", recipe: double(id: 1, servings: "4 servings"))
      without_servings = double("Meal", title: "Mystery Stew", recipe: double(id: 2, servings: nil))
      stub_paprika(scheduled_meals: [ with_servings, without_servings ])

      get nutrition_path

      expect(response.body).to match(/Granola\s*<span[^>]*>\s*\|\s*<\/span>\s*4/)
      expect(response.body).not_to match(/Mystery Stew\s*<span/)
    end

    it "shows each nutrient against its goal with the remaining difference" do
      user.create_settings!(calorie_goal: 2000, protein_goal: 100, carbs_goal: 200, fat_goal: 70)
      user.nutrition_entries.create!(logged_on: Date.current, item: "x", calories: 1500, protein: 120)

      get nutrition_path

      expect(response.body).to include("1500 / 2000")
      expect(response.body).to include("500 left")   # calories under goal
      expect(response.body).to include("20g over")   # protein over goal
    end

    it "renders a dropdown option for each other recipe" do
      stub_paprika(other_recipes: [ double(id: 7, name: "Zuppa Toscana") ])

      get nutrition_path

      expect(response.body).to include("Zuppa Toscana")
      expect(response.body).to include("meal-picker#pick")
    end

    it "renders a pill for each staple recipe" do
      stub_paprika(staple_recipes: [ double(id: 88, name: "Weekly Overnight Oats", servings: "2") ])

      get nutrition_path

      expect(response.body).to include("Weekly Overnight Oats")
      expect(response.body).to include("88")
    end
  end

  describe "GET /nutrition/history" do
    it "renders a row per logged day with totals" do
      user.nutrition_entries.create!(logged_on: Date.new(2026, 6, 28), item: "eggs", calories: 150, protein: 12)
      user.nutrition_entries.create!(logged_on: Date.new(2026, 6, 29), item: "banana", calories: 100, protein: 1)

      get nutrition_history_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nutrition History")
      expect(response.body).to include("Jun 29, 2026")
      expect(response.body).to include("Jun 28, 2026")
      expect(response.body).to include("nutrition-chart")
      expect(response.body).to include("data-nutrition-chart-series-value")
    end

    it "shows an empty state when nothing is logged" do
      get nutrition_history_path
      expect(response.body).to include("Nothing logged yet")
    end

    it "passes the user's goals to the chart when set" do
      user.create_settings!(calorie_goal: 2000, protein_goal: 100, carbs_goal: 200, fat_goal: 70)
      user.nutrition_entries.create!(logged_on: Date.current, item: "x", calories: 500)

      get nutrition_history_path

      expect(response.body).to include("data-nutrition-chart-goals-value")
      expect(response.body).to include("2000")
    end
  end

  describe "recipe links in the log" do
    it "links a logged entry's recipe to its recipe page" do
      entry = user.nutrition_entries.create!(logged_on: Date.current, item: "chili", recipe_match: "Chili")
      entry.nutrition_entry_recipes.create!(recipe_id: 42)

      get nutrition_path

      expect(response.body).to include(recipe_path(42))
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

    it "responds 422 with a red alert (and keeps no data) when the LLM errors" do
      error_result = NutritionParser::Result.new(
        entries: [], reply: "The nutrition assistant is temporarily unavailable (error 503).", error: true
      )
      allow(NutritionParser).to receive(:new).and_return(instance_double(NutritionParser, parse: error_result))

      expect do
        post nutrition_log_path, params: { message: "a banana" }, as: :turbo_stream
      end.not_to change(NutritionEntry, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("alert-danger")
      expect(response.body).to include("temporarily unavailable")
    end

    it "returns a friendly 422 without calling the LLM when no API key is configured" do
      allow(GeminiService).to receive(:configured?).and_return(false)
      expect(NutritionParser).not_to receive(:new)

      post nutrition_log_path, params: { message: "a banana" }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("no Gemini API key is configured")
    end

    it "does not call the parser or create entries for a blank message" do
      expect(NutritionParser).not_to receive(:new)

      expect do
        post nutrition_log_path, params: { message: "   " }, as: :turbo_stream
      end.not_to change(NutritionEntry, :count)

      expect(response.body).to include("Tell me what you ate")
    end

    context "deleting entries" do
      let!(:entry) { user.nutrition_entries.create!(logged_on: Date.new(2026, 6, 29), item: "banana", calories: 100) }
      let!(:other) { user.nutrition_entries.create!(logged_on: Date.new(2026, 6, 29), item: "eggs", calories: 150) }

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

    context "bulk actions" do
      let!(:a) { user.nutrition_entries.create!(logged_on: Date.new(2026, 6, 29), item: "banana", calories: 100) }
      let!(:b) { user.nutrition_entries.create!(logged_on: Date.new(2026, 6, 29), item: "eggs", calories: 150) }
      let!(:keep) { user.nutrition_entries.create!(logged_on: Date.new(2026, 6, 29), item: "toast", calories: 90) }

      it "deletes the selected entries" do
        expect do
          post nutrition_bulk_path,
               params: { date: "2026-06-29", bulk_action: "delete", entry_ids: [ a.id, b.id ] },
               as: :turbo_stream
        end.to change(NutritionEntry, :count).by(-2)

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("Deleted 2 entries")
        expect(NutritionEntry.exists?(keep.id)).to be(true)
      end

      it "moves the selected entries to another date" do
        post nutrition_bulk_path,
             params: { date: "2026-06-29", bulk_action: "move", target_date: "2026-07-01", entry_ids: [ a.id ] },
             as: :turbo_stream

        expect(a.reload.logged_on).to eq(Date.new(2026, 7, 1))
        expect(b.reload.logged_on).to eq(Date.new(2026, 6, 29))
        expect(response.body).to include("Moved 1 entry to July 1")
      end

      it "reports when a move has no target date" do
        post nutrition_bulk_path,
             params: { date: "2026-06-29", bulk_action: "move", target_date: "", entry_ids: [ a.id ] },
             as: :turbo_stream

        expect(a.reload.logged_on).to eq(Date.new(2026, 6, 29))
        expect(response.body).to include("Pick a date")
      end

      it "reports when nothing is selected" do
        post nutrition_bulk_path,
             params: { date: "2026-06-29", bulk_action: "delete" },
             as: :turbo_stream

        expect(response.body).to include("No entries selected")
      end
    end

    context "syncing meals" do
      it "runs a sync and refreshes the pills via turbo stream" do
        result = PaprikaSync::Result.new(categories: 30, recipes_changed: 2, meals: 5)
        allow(PaprikaSync).to receive(:new).and_return(instance_double(PaprikaSync, call: result))

        post nutrition_sync_path(date: "2026-06-29"), as: :turbo_stream

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("recipe_choices")
        expect(response.body).to include("Synced from Paprika — 5 meals, 2 recipes updated")
      end

      it "reports a friendly message when the sync fails" do
        allow(PaprikaSync).to receive(:new).and_raise(StandardError, "boom")

        post nutrition_sync_path(date: "2026-06-29"), as: :turbo_stream

        expect(response.body).to include("Sync failed: boom")
      end

      it "redirects for an HTML request" do
        allow(PaprikaSync).to receive(:new)
          .and_return(instance_double(PaprikaSync, call: PaprikaSync::Result.new(categories: 0, recipes_changed: 0, meals: 0)))

        post nutrition_sync_path(date: "2026-06-29")

        expect(response).to redirect_to(nutrition_path(date: Date.new(2026, 6, 29)))
      end
    end

    context "editing an entry" do
      let!(:entry) do
        user.nutrition_entries.create!(logged_on: Date.new(2026, 6, 29), item: "banana", calories: 100, protein: 1)
      end

      it "renders the edit form" do
        get edit_nutrition_entry_path(entry)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit Entry")
        expect(response.body).to include("banana")
      end

      it "applies corrections and redirects back to the day" do
        patch nutrition_entry_path(entry), params: {
          nutrition_entry: { item: "large banana", calories: 120, protein: 2, fiber: 4 }
        }

        expect(response).to redirect_to(nutrition_path(date: Date.new(2026, 6, 29)))
        entry.reload
        expect(entry.item).to eq("large banana")
        expect(entry.calories).to eq(120)
        expect(entry.fiber).to eq(4)
      end

      it "re-renders the form when the update is invalid" do
        patch nutrition_entry_path(entry), params: { nutrition_entry: { item: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Edit Entry")
      end
    end

    context "when items match selected recipes" do
      let(:chili) do
        instance_double(Paprika::Recipe, id: 42, name: "Chili", nutritional_info: "Calories: 999", servings: nil)
      end
      let(:salad) do
        instance_double(Paprika::Recipe, id: 7, name: "Bean Salad", nutritional_info: nil, servings: "Serves 4")
      end
      let(:result) do
        NutritionParser::Result.new(
          entries: [
            { "item" => "medium bowl chili", "calories" => 600, "protein" => 45, "carbs" => 30, "fat" => 20,
              "fiber" => 12, "saturated_fat" => 6, "sugar" => 5,
              "recipe_id" => 42, "batch_servings" => 4,
              "batch_macros" => { "calories" => 2400, "protein" => 180, "carbs" => 120, "fat" => 80, "fiber" => 48, "saturated_fat" => 24, "sugar" => 20 } },
            { "item" => "small bowl bean salad", "calories" => 200, "protein" => 8, "carbs" => 25, "fat" => 6,
              "recipe_id" => 7, "batch_servings" => 5,
              "batch_macros" => { "calories" => 800, "protein" => 32, "carbs" => 100, "fat" => 24, "fiber" => 40, "saturated_fat" => 8, "sugar" => 16 } }
          ],
          reply: "Logged both."
        )
      end

      before do
        allow(Paprika::Recipe).to receive(:where).with(Z_PK: [ 42, 7 ]).and_return([ chili, salad ])
        allow(chili).to receive(:update_nutritional_info!)
        allow(salad).to receive(:update_nutritional_info!)
        allow(chili).to receive(:update_servings!)
        allow(salad).to receive(:update_servings!)
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
          "Meal Total (AI Generated - 7/2/26)\nCalories: 2400 kcal\nProtein: 180 g\nCarbohydrates: 120 g\nFat: 80 g\nFiber: 48 g\nSaturated Fat: 24 g\nSugar: 20 g"
        )
        expect(salad).to receive(:update_nutritional_info!).with(
          "Meal Total (AI Generated - 7/2/26)\nCalories: 800 kcal\nProtein: 32 g\nCarbohydrates: 100 g\nFat: 24 g\nFiber: 40 g\nSaturated Fat: 8 g\nSugar: 16 g"
        )

        post nutrition_log_path, params: { message: "chili and salad", recipe_ids: [ 42, 7 ] },
                                 as: :turbo_stream
      end

      it "standardizes each matched recipe's serving count" do
        expect(chili).to receive(:update_servings!).with(ServingsSkill.format(4))
        expect(salad).to receive(:update_servings!).with(ServingsSkill.format(5))

        post nutrition_log_path, params: { message: "chili and salad", recipe_ids: [ 42, 7 ] },
                                 as: :turbo_stream
      end

      it "does not write to recipes in read-only mode" do
        allow(NutritionSkill).to receive(:write_enabled?).and_return(false)
        expect(chili).not_to receive(:update_nutritional_info!)
        expect(salad).not_to receive(:update_nutritional_info!)
        expect(chili).not_to receive(:update_servings!)
        expect(salad).not_to receive(:update_servings!)

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

      it "still logs the entry when writing servings back fails" do
        allow(salad).to receive(:update_servings!).and_raise(StandardError, "db locked")
        allow(Rails.logger).to receive(:warn)

        expect do
          post nutrition_log_path, params: { message: "chili and salad", recipe_ids: [ 42, 7 ] },
                                   as: :turbo_stream
        end.to change(NutritionEntry, :count).by(2)

        expect(Rails.logger).to have_received(:warn).with(/Failed to write servings for Bean Salad/)
      end
    end
  end

  describe "POST /nutrition/log — no-LLM and verified paths" do
    def stub_selected(recipe)
      allow(Paprika::Recipe).to receive(:where).with(Z_PK: [ recipe.id ]).and_return([ recipe ])
    end

    it "logs directly from a Verified recipe without calling the LLM" do
      recipe = instance_double(Paprika::Recipe, id: 569, name: "Eggs And Beans",
        nutritional_info: "Verified\nCalories: 298\nProtein: 24\nCarbohydrates: 32\nFat: 5\nFiber: 7\nSaturated Fat: 2\nSugar: 2")
      stub_selected(recipe)
      expect(NutritionParser).not_to receive(:new)

      expect do
        post nutrition_log_path, params: { message: "Eggs And Beans", recipe_ids: [ 569 ] }, as: :turbo_stream
      end.to change(NutritionEntry, :count).by(1)

      entry = NutritionEntry.last
      expect(entry.item).to eq("Eggs And Beans")
      expect(entry.calories).to eq(298)
      expect(entry.protein).to eq(24)
      expect(entry.nutrition_entry_recipes.pluck(:recipe_id)).to eq([ 569 ])
      expect(response.body).to include("from saved nutrition")
    end

    it "logs directly from an AI-generated block without the LLM" do
      recipe = instance_double(Paprika::Recipe, id: 8, name: "Batch Chili",
        nutritional_info: "Meal Total (AI Generated - 7/2/26)\nCalories: 2400 kcal\nProtein: 180 g\nCarbohydrates: 120 g\nFat: 80 g\nFiber: 40 g\nSaturated Fat: 25 g\nSugar: 30 g")
      stub_selected(recipe)
      expect(NutritionParser).not_to receive(:new)

      post nutrition_log_path, params: { message: "Batch Chili", recipe_ids: [ 8 ] }, as: :turbo_stream

      expect(NutritionEntry.last.calories).to eq(2400)
    end

    it "falls back to the LLM when a named recipe has no local nutrition" do
      recipe = instance_double(Paprika::Recipe, id: 9, name: "Mystery Stew", nutritional_info: nil)
      stub_selected(recipe)
      parser = instance_double(NutritionParser, parse:
        NutritionParser::Result.new(entries: [], reply: "Hmm."))
      expect(NutritionParser).to receive(:new).and_return(parser)

      post nutrition_log_path, params: { message: "Mystery Stew", recipe_ids: [ 9 ] }, as: :turbo_stream
    end

    context "explicit serving-count portions (no LLM)" do
      # Batch nutrition for a recipe that yields 8 — one serving is 1/8 of these.
      let(:chili) do
        instance_double(Paprika::Recipe, id: 88, name: "Vegan Black Beans Chili",
          servings: "8 servings (AI Generated - 7/8/26)",
          nutritional_info: "Meal Total (AI Generated - 7/2/26)\nCalories: 3051 kcal\nProtein: 160 g\n" \
                            "Carbohydrates: 480 g\nFat: 40 g\nFiber: 96 g\nSaturated Fat: 8 g\nSugar: 24 g")
      end

      before { stub_selected(chili) }

      it "divides the batch by the yield for one serving, without the LLM" do
        expect(NutritionParser).not_to receive(:new)

        expect do
          post nutrition_log_path, params: { message: "1 serving Vegan Black Beans Chili", recipe_ids: [ 88 ] },
                                   as: :turbo_stream
        end.to change(NutritionEntry, :count).by(1)

        entry = NutritionEntry.last
        expect(entry.item).to eq("1 serving Vegan Black Beans Chili")
        expect(entry.calories).to eq(381) # 3051 / 8, not the whole pot
        expect(entry.protein).to eq(20)   # 160 / 8
        expect(entry.fiber).to eq(12)     # 96 / 8
        expect(entry.nutrition_entry_recipes.pluck(:recipe_id)).to eq([ 88 ])
        expect(response.body).to include("from saved nutrition")
      end

      it "scales a half serving and pluralizes the label" do
        post nutrition_log_path, params: { message: "0.5 serving Vegan Black Beans Chili", recipe_ids: [ 88 ] },
                                 as: :turbo_stream

        entry = NutritionEntry.last
        expect(entry.item).to eq("0.5 servings Vegan Black Beans Chili")
        expect(entry.calories).to eq(191) # 3051 / 8 * 0.5 = 190.6875
      end

      it "scales one-and-a-half servings regardless of pill order" do
        post nutrition_log_path, params: { message: "Vegan Black Beans Chili 1.5 servings", recipe_ids: [ 88 ] },
                                 as: :turbo_stream

        entry = NutritionEntry.last
        expect(entry.item).to eq("1.5 servings Vegan Black Beans Chili")
        expect(entry.calories).to eq(572) # 3051 / 8 * 1.5 = 572.0625
      end

      it "divides a Verified label by its serving count too" do
        recipe = instance_double(Paprika::Recipe, id: 12, name: "Eggs And Beans",
          servings: "Verified 4 servings",
          nutritional_info: "Verified\nCalories: 1200\nProtein: 96")
        stub_selected(recipe)
        expect(NutritionParser).not_to receive(:new)

        post nutrition_log_path, params: { message: "1 serving Eggs And Beans", recipe_ids: [ 12 ] }, as: :turbo_stream

        entry = NutritionEntry.last
        expect(entry.calories).to eq(300) # 1200 / 4
        expect(entry.protein).to eq(24)   # 96 / 4
      end

      it "falls back to the LLM when the recipe has no parseable yield" do
        recipe = instance_double(Paprika::Recipe, id: 13, name: "Yieldless Stew", servings: nil,
          nutritional_info: "Meal Total (AI Generated - 7/2/26)\nCalories: 800 kcal")
        stub_selected(recipe)
        parser = instance_double(NutritionParser, parse: NutritionParser::Result.new(entries: [], reply: "Hmm."))
        expect(NutritionParser).to receive(:new).and_return(parser)

        post nutrition_log_path, params: { message: "1 serving Yieldless Stew", recipe_ids: [ 13 ] }, as: :turbo_stream
      end

      it "falls back to the LLM when the recipe has no local nutrition to scale" do
        recipe = instance_double(Paprika::Recipe, id: 14, name: "Blank Stew", servings: "Serves 6", nutritional_info: nil)
        stub_selected(recipe)
        parser = instance_double(NutritionParser, parse: NutritionParser::Result.new(entries: [], reply: "Hmm."))
        expect(NutritionParser).to receive(:new).and_return(parser)

        post nutrition_log_path, params: { message: "2 servings Blank Stew", recipe_ids: [ 14 ] }, as: :turbo_stream
      end
    end

    context "Verified recipe via the LLM (with a fraction)" do
      let(:recipe) do
        instance_double(Paprika::Recipe, id: 42, name: "Chili", servings: "Verified 4 servings",
          nutritional_info: "Verified\nCalories: 800\nProtein: 40")
      end

      before { stub_selected(recipe) }

      it "scales the label by the fraction, never overwrites, and flags missing data" do
        allow(NutritionParser).to receive(:new).and_return(instance_double(NutritionParser, parse:
          NutritionParser::Result.new(
            entries: [ { "item" => "half the chili", "calories" => 999, "recipe_id" => 42,
                         "recipe_fraction" => 0.5, "batch_macros" => nil } ],
            reply: "Logged."
          )))
        expect(recipe).not_to receive(:update_nutritional_info!)

        post nutrition_log_path, params: { message: "half the chili", recipe_ids: [ 42 ] }, as: :turbo_stream

        entry = NutritionEntry.last
        expect(entry.calories).to eq(400) # 800 * 0.5 from the label, not the LLM's 999
        expect(entry.protein).to eq(20)
        expect(response.body).to include("These recipes need more nutrition data: Chili")
      end

      it "uses the LLM macros when no fraction is given" do
        allow(NutritionParser).to receive(:new).and_return(instance_double(NutritionParser, parse:
          NutritionParser::Result.new(
            entries: [ { "item" => "some chili", "calories" => 123, "recipe_id" => 42,
                         "recipe_fraction" => nil, "batch_macros" => nil } ],
            reply: "Logged."
          )))

        post nutrition_log_path, params: { message: "some chili", recipe_ids: [ 42 ] }, as: :turbo_stream

        expect(NutritionEntry.last.calories).to eq(123)
      end
    end
  end
end
