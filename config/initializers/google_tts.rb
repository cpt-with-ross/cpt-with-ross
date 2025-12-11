# frozen_string_literal: true

# =============================================================================
# Google Cloud Text-to-Speech Configuration
# =============================================================================
#
# Configures TTS settings for converting AI chat responses to audio.
# Uses Application Default Credentials (ADC) via the googleauth gem.
# The same service account used for Vertex AI has TTS permissions.
#
# Voice Selection: en-US-Neural2-J
# - Neural2 voice (upgraded from Wavenet, more natural prosody)
# - Supports SSML marks for word-level highlighting
# - Male voice: clear, professional, slightly deeper than D variant
# - Well-suited for informational/therapeutic content
# - Audio profile optimized for loud speaker demonstrations
# Note: Studio voices don't support <mark> tags needed for timepoints
#
require 'google/cloud/text_to_speech/v1beta1'

Rails.application.config.after_initialize do
  Rails.application.config.google_tts = {
    # Voice configuration - warm professional male voice
    voice: {
      language_code: 'en-US',
      name: 'en-US-Neural2-J',
      ssml_gender: :MALE
    },
    # Audio output configuration - optimized for Neural2-J + loud speaker demos
    audio_config: {
      audio_encoding: :MP3,
      speaking_rate: 0.94,          # Neural2 handles near-normal speed well; clear yet conversational
      pitch: -1.0,                  # Subtle warmth; J variant is already deeper than D
      volume_gain_db: 2.0,          # Slight boost for speaker projection
      sample_rate_hertz: 24_000,    # Higher quality audio
      effects_profile_id: ['large-home-entertainment-class-device']
    }
  }
end
