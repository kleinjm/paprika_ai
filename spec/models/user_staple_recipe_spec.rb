require "rails_helper"

# == Schema Information
#
# Table name: user_staple_recipes
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  recipe_id  :integer          not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_staples_on_user_and_recipe      (user_id,recipe_id) UNIQUE
#  index_user_staple_recipes_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
RSpec.describe UserStapleRecipe do
  let(:user) { User.create!(email: "staple@example.com", password: "password") }

  it "requires a recipe_id" do
    record = described_class.new(user: user)
    expect(record).not_to be_valid
    expect(record.errors[:recipe_id]).not_to be_empty
  end

  it "is unique per recipe within a user" do
    user.user_staple_recipes.create!(recipe_id: 42)
    dup = user.user_staple_recipes.build(recipe_id: 42)
    expect(dup).not_to be_valid
  end

  describe "#recipe" do
    it "looks up the Paprika recipe by Z_PK" do
      record = user.user_staple_recipes.create!(recipe_id: 42)
      recipe = double("Recipe")
      expect(Paprika::Recipe).to receive(:find_by).with(Z_PK: 42).and_return(recipe)

      expect(record.recipe).to eq(recipe)
    end
  end
end
