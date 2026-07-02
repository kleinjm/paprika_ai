require "rails_helper"

RSpec.describe "UserSettings", type: :request do
  let(:user) { User.create!(email: "goals@example.com", password: "password") }

  before { sign_in user }

  describe "GET edit" do
    it "renders the four goal inputs" do
      get edit_nutrition_goals_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit Nutrition Goals")
      expect(response.body).to include("user_settings[calorie_goal]")
      expect(response.body).to include("user_settings[protein_goal]")
      expect(response.body).to include("user_settings[carbs_goal]")
      expect(response.body).to include("user_settings[fat_goal]")
    end
  end

  describe "PATCH update" do
    it "saves goals and redirects to the profile" do
      expect do
        patch nutrition_goals_path, params: {
          user_settings: { calorie_goal: 2600, protein_goal: 190, carbs_goal: 260, fat_goal: 85 }
        }
      end.to change { user.reload.settings }.from(nil).to(be_present)

      expect(response).to redirect_to(profile_path)
      expect(user.settings.calorie_goal).to eq(2600)
      expect(user.settings.fat_goal).to eq(85)
    end

    it "updates existing goals" do
      user.create_settings!(calorie_goal: 2000)
      patch nutrition_goals_path, params: { user_settings: { calorie_goal: 2200 } }
      expect(user.reload.settings.calorie_goal).to eq(2200)
    end

    it "re-renders the form when invalid" do
      patch nutrition_goals_path, params: { user_settings: { calorie_goal: -1 } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Edit Nutrition Goals")
    end
  end
end
