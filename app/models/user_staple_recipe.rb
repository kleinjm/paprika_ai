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
class UserStapleRecipe < ApplicationRecord
  belongs_to :user

  validates :recipe_id, presence: true, uniqueness: { scope: :user_id }

  # The Paprika recipe lives in the read-only Paprika database, so it can't be a
  # real Active Record association across connections.
  def recipe
    Paprika::Recipe.find_by(Z_PK: recipe_id)
  end
end
