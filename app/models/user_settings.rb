# == Schema Information
#
# Table name: user_settings
#
#  id           :bigint           not null, primary key
#  calorie_goal :integer
#  carbs_goal   :integer
#  fat_goal     :integer
#  protein_goal :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_user_settings_on_user_id  (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserSettings < ApplicationRecord
  belongs_to :user

  GOALS = %i[calorie_goal protein_goal carbs_goal fat_goal].freeze

  validates(*GOALS, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true)
end
