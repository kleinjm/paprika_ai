# Loaded automatically by SimpleCov (recurses up from the working directory)
# whenever `require "simplecov"` runs, so coverage config lives in one place.
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/config/"
  add_filter "/db/"
  add_filter "/app/models/paprika/"
  add_filter "/app/services/chat_gpt_service.rb"
  minimum_coverage 100
end
