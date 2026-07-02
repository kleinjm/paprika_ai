require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { User.create!(email: "profile@example.com", password: "password") }

  before { sign_in user }

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
end
