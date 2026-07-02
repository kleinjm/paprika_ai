require "rails_helper"

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
RSpec.describe UserSettings do
  let(:user) { User.create!(email: "settings@example.com", password: "password") }

  it "belongs to a user and stores goals" do
    settings = user.create_settings!(calorie_goal: 2500, protein_goal: 180, carbs_goal: 250, fat_goal: 80)
    expect(settings.user).to eq(user)
    expect(user.reload.settings).to eq(settings)
  end

  it "rejects negative goals" do
    settings = UserSettings.new(user: user, calorie_goal: -5)
    expect(settings).not_to be_valid
    expect(settings.errors[:calorie_goal]).not_to be_empty
  end

  it "allows blank goals" do
    expect(UserSettings.new(user: user)).to be_valid
  end

  describe "User#settings_or_build" do
    it "builds a new settings record when none exists" do
      expect(user.settings).to be_nil
      expect(user.settings_or_build).to be_a(UserSettings)
      expect(user.settings_or_build).not_to be_persisted
    end

    it "returns the existing settings record" do
      existing = user.create_settings!(calorie_goal: 2000)
      expect(user.settings_or_build).to eq(existing)
    end
  end
end
