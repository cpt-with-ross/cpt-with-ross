RubyLLM.configure do |config|
  config.openai_api_key = ENV['GITHUB_TOKEN'] # Key for your endpoint
  config.openai_api_base = "https://models.inference.ai.azure.com" # Your endpoint
  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end
