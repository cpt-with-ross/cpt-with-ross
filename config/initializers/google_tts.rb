# frozen_string_literal: true

# =============================================================================
# Google Cloud Text-to-Speech Configuration
# =============================================================================
#
# Configures TTS settings for converting AI chat responses to audio.
# Uses Application Default Credentials (ADC) via the googleauth gem.
# The same service account used for Vertex AI has TTS permissions.
#
# Voice Selection: en-US-Wavenet-D
# - High-quality Wavenet voice (supports SSML marks for word highlighting)
# - Male voice with warm, professional tone suitable for therapy
# - Speaking rate slightly slower (0.95) for calm, therapeutic delivery
# - Pitch slightly lower (-1.0) for warmth and trust
# Note: Studio voices don't support <mark> tags needed for timepoints
#
require 'google/cloud/text_to_speech/v1beta1'

Rails.application.config.after_initialize do
  Rails.application.config.google_tts = {
    # Voice configuration - warm professional male voice
    voice: {
      language_code: 'en-US',
      name: 'en-US-Wavenet-D',
      ssml_gender: :MALE
    },
    # Audio output configuration
    audio_config: {
      audio_encoding: :MP3,
      speaking_rate: 0.95,  # Slightly slower for therapy context
      pitch: -1.0           # Slightly lower for warmth
    }
  }
end
