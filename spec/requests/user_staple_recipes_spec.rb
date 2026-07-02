require "rails_helper"

RSpec.describe "UserStapleRecipes", type: :request do
  let(:user) { User.create!(email: "staples@example.com", password: "password") }

  before { sign_in user }

  describe "POST create" do
    it "adds a staple recipe and redirects to the profile" do
      expect do
        post staple_recipes_path, params: { recipe_id: 42 }
      end.to change(user.user_staple_recipes, :count).by(1)

      expect(response).to redirect_to(profile_path)
      expect(user.user_staple_recipes.pluck(:recipe_id)).to include(42)
    end

    it "ignores a blank selection" do
      expect do
        post staple_recipes_path, params: { recipe_id: "" }
      end.not_to change(UserStapleRecipe, :count)
    end

    it "is idempotent for an already-added recipe" do
      user.user_staple_recipes.create!(recipe_id: 42)
      expect do
        post staple_recipes_path, params: { recipe_id: 42 }
      end.not_to change(UserStapleRecipe, :count)
    end
  end

  describe "DELETE destroy" do
    it "removes the staple recipe" do
      staple = user.user_staple_recipes.create!(recipe_id: 42)

      expect do
        delete staple_recipe_path(staple)
      end.to change(user.user_staple_recipes, :count).by(-1)

      expect(response).to redirect_to(profile_path)
    end
  end
end
