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

  # Write AI-computed nutrition back to a recipe in the Paprika cloud.
  def push_nutritional_info(uid:, text:)
    update_recipe(uid, nutritional_info: text)
  end

  # Write rewritten (shorthand) directions back to a recipe in the Paprika cloud.
  def push_directions(uid:, text:)
    update_recipe(uid, directions: text)
  end

  # Write an AI-estimated serving count back to a recipe in the Paprika cloud.
  def push_servings(uid:, text:)
    update_recipe(uid, servings: text)
  end

  # Update one or more fields on a cloud recipe. Fetches the current recipe (for
  # the full field set), applies the changes, and saves (which recomputes the
  # sync hash and notifies the apps). The cloud is the source of truth; the
  # local mirror picks the change up on the next PaprikaSync.
  def update_recipe(uid, **fields)
    recipe = client.recipe(uid)
    fields.each { |key, value| recipe[key.to_s] = value }
    client.save_recipe(recipe)
  end
end
