require "rails_helper"

RSpec.describe "Recipes", type: :request do
  let(:user) { User.create!(email: "recipes@example.com", password: "password") }

  before { sign_in user }

  it "requires authentication" do
    sign_out user
    get recipe_path(1)
    expect(response).to redirect_to(new_user_session_path)
  end

  it "shows the recipe's details" do
    recipe = double("Recipe", id: 569, name: "Eggs And Beans",
      recipe_categories: [ double(name: "Breakfast") ],
      nutritional_info: "Verified\nCalories: 298",
      ingredients: "2 eggs\n1 cup beans",
      directions: "Cook the eggs. Warm the beans.")
    allow(Paprika::Recipe).to receive(:find_by!).with(Z_PK: "569").and_return(recipe)

    get recipe_path(569)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Eggs And Beans")
    expect(response.body).to include("Breakfast")
    expect(response.body).to include("1 cup beans")
    expect(response.body).to include("Warm the beans")
  end
end
