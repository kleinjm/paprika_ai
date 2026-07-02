require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { User.create!(email: "profile@example.com", password: "password") }

  before do
    sign_in user
    allow(Paprika::Recipe).to receive(:not_trashed_in).and_return([])
    allow(Paprika::Recipe).to receive(:not_trashed_excluding).and_return([])
  end

  it "requires authentication" do
    sign_out user
    get profile_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "shows the email and an edit-goals link" do
    get profile_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("profile@example.com")
    expect(response.body).to include("Edit Nutrition Goals")
    expect(response.body).to include(edit_nutrition_goals_path)
  end

  it "shows current goals when set" do
    user.create_settings!(calorie_goal: 2500, protein_goal: 180)
    get profile_path
    expect(response.body).to include("2500")
    expect(response.body).to include("180g")
  end

  describe "staple recipes section" do
    it "shows a dropdown of available recipes" do
      allow(Paprika::Recipe).to receive(:not_trashed_excluding).and_return([ double(id: 5, name: "Zuppa Toscana") ])

      get profile_path

      expect(response.body).to include("Staple Recipes")
      expect(response.body).to include("Zuppa Toscana")
    end

    it "lists the user's staples with a remove button" do
      staple = user.user_staple_recipes.create!(recipe_id: 42)
      allow(Paprika::Recipe).to receive(:not_trashed_in).and_return([ double(id: 42, name: "Chili") ])

      get profile_path

      expect(response.body).to include("Chili")
      expect(response.body).to include(staple_recipe_path(staple))
    end
  end
end
