# frozen_string_literal: true

# Thin wrapper around the paprika_client gem, configured from Rails
# credentials (paprika.email / paprika.password). Single place the app talks to
# the Paprika cloud sync API.
module PaprikaCloud
  module_function

  def client
    creds = Rails.application.credentials.paprika
    raise "Missing Paprika credentials (paprika.email / paprika.password)" unless creds

    PaprikaClient::Client.new(email: creds[:email], password: creds[:password])
  end

  # Write AI-computed nutrition back to a recipe in the Paprika cloud. Fetches
  # the current recipe (for the full field set), updates nutritional_info, and
  # saves (which recomputes the sync hash and notifies the apps).
  def push_nutritional_info(uid:, text:)
    recipe = client.recipe(uid)
    recipe.nutritional_info = text
    client.save_recipe(recipe)
  end
end
