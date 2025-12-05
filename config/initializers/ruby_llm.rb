RubyLLM.configure do |config|
  # Google Vertex AI configuration with Application Default Credentials (ADC)
  # ADC is automatically discovered by googleauth gem from GOOGLE_APPLICATION_CREDENTIALS
  config.vertexai_project_id = ENV['GOOGLE_CLOUD_PROJECT'] || Rails.application.credentials.dig(:google, :project_id)
  config.vertexai_location = ENV['GOOGLE_CLOUD_LOCATION'] || 'us-central1'

  # Use Vertex AI as the default provider with Gemini model
  config.default_model = 'gemini-2.5-flash'

  # Use the new association-based acts_as API (recommended)
  config.use_new_acts_as = true
end

# Centralized CPT chat configuration
Rails.application.config.after_initialize do
  Rails.application.config.cpt_chat = {
    default_model_id: 'gemini-2.5-flash',
    default_provider: 'vertexai',
    embedding_model_id: 'text-embedding-004',
    embedding_provider: 'vertexai'
  }
end
