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
      servings: "Serves 4",
      display_image_url: "https://example.com/eggs.jpg",
      nutritional_info: "Verified\nCalories: 298",
      ingredients: "2 eggs\n1 cup beans",
      directions: "Cook the eggs. Warm the beans.")
    allow(Paprika::Recipe).to receive(:find_by!).with(Z_PK: "569").and_return(recipe)

    get recipe_path(569)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Eggs And Beans")
    expect(response.body).to include("Breakfast")
    expect(response.body).to include("Serves 4")
    expect(response.body).to include("https://example.com/eggs.jpg")
    expect(response.body).to include("1 cup beans")
    expect(response.body).to include("Warm the beans")
  end

  it "shows the shorthand rewrite for review on the edit page" do
    recipe = double("Recipe", id: 569, name: "Eggs And Beans",
      directions: "Cook the eggs. Warm the beans.")
    allow(Paprika::Recipe).to receive(:find_by!).with(Z_PK: "569").and_return(recipe)
    allow(RecipeShorthand).to receive(:new)
      .and_return(instance_double(RecipeShorthand, rewrite: "eggs -> fry; beans -> warm"))

    get edit_recipe_path(569)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cook the eggs")             # original directions
    expect(response.body).to include("eggs -&gt; fry; beans -&gt; warm") # rewritten shorthand
  end

  it "saves edited directions and redirects to the recipe" do
    recipe = double("Recipe", id: 569)
    allow(Paprika::Recipe).to receive(:find_by!).with(Z_PK: "569").and_return(recipe)
    expect(recipe).to receive(:update_directions!).with("eggs -> fry")

    patch recipe_path(569), params: { recipe: { directions: "eggs -> fry" } }

    expect(response).to redirect_to(recipe_path(569))
  end

  it "lists recipes and filters by an ILIKE name search" do
    matching = Paprika::Recipe.none
    relation = instance_double(ActiveRecord::Relation)
    allow(Paprika::Recipe).to receive(:not_trashed).and_return(relation)
    allow(relation).to receive(:order).with(:ZNAME).and_return(relation)
    allow(relation).to receive(:where).with('"ZNAME" ILIKE ?', "%chili%").and_return(matching)

    get recipes_path(q: "chili")

    expect(response).to have_http_status(:ok)
    expect(relation).to have_received(:where).with('"ZNAME" ILIKE ?', "%chili%")
  end
end
