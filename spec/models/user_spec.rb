require "rails_helper"

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
RSpec.describe User do
  it "is valid with an email and password" do
    expect(User.new(email: "a@example.com", password: "password")).to be_valid
  end

  it "requires an email" do
    user = User.new(password: "password")
    expect(user).not_to be_valid
    expect(user.errors[:email]).not_to be_empty
  end

  it "owns nutrition entries and destroys them with the user" do
    user = User.create!(email: "owner@example.com", password: "password")
    user.nutrition_entries.create!(logged_on: Date.current, item: "eggs")

    expect { user.destroy }.to change(NutritionEntry, :count).by(-1)
  end
end
