# frozen_string_literal: true

# =============================================================================
# ActiveStorage Configuration
# =============================================================================
#
# Configures cache headers for ActiveStorage blobs, particularly for
# TTS audio files which are immutable and can be cached aggressively.
#
Rails.application.config.after_initialize do
  ActiveStorage::Blobs::ProxyController.class_eval do
    before_action :set_audio_cache_headers, only: [:show]

    private

    def set_audio_cache_headers
      return unless @blob&.audio?

      # Audio files are immutable once generated - cache for 1 year
      # This enables efficient browser caching and CDN edge caching
      response.headers['Cache-Control'] = 'public, max-age=31536000, immutable'
    end
  end
end
