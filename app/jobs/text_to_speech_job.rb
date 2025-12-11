# frozen_string_literal: true

# =============================================================================
# TextToSpeechJob - Convert Message Content to Audio via Google Cloud TTS
# =============================================================================
#
# Converts assistant message text to audio using Google Cloud Text-to-Speech.
# Uses SSML with marks to get word-level timestamps for synchronized text
# highlighting during audio playback.
#
# Flow:
# 1. Skip if not assistant message or already has audio (idempotency)
# 2. Convert content to SSML with word marks
# 3. Call Google TTS API with timepoint request
# 4. Parse timepoints from response
# 5. Attach audio to message via ActiveStorage
# 6. Store timepoints in tts_timepoints column
# 7. Broadcast completion to update UI (spinner -> play button)
#
# Enqueue Location:
# Called from ChatResponseJob after message.update!(content: ...) succeeds
#
class TextToSpeechJob < ApplicationJob
  queue_as :background

  # Google TTS has a ~5000 char limit; use buffer to avoid edge cases
  MAX_TTS_CONTENT_LENGTH = 4000

  # Retry only on transient errors that may resolve
  retry_on Google::Cloud::ResourceExhaustedError,
           Google::Cloud::InternalError,
           Google::Cloud::DeadlineExceededError,
           wait: :polynomially_longer, attempts: 3

  def perform(message_id)
    # Use find_by to handle message deleted while job was queued
    message = Message.find_by(id: message_id)
    return unless message

    # Only process assistant messages with content
    return unless message.role == 'assistant' && message.content.present?

    # Skip if audio already attached (idempotency for job retries)
    return if message.audio.attached?

    # Validate content length before API call
    if message.content.length > MAX_TTS_CONTENT_LENGTH
      Rails.logger.warn("TTS skipped: message #{message_id} too long (#{message.content.length} chars)")
      broadcast_tts_unavailable(message)
      return
    end

    # Generate SSML with word marks for timing
    ssml_content, word_list = build_ssml_with_marks(message.content)

    # Call Google TTS API
    response = synthesize_speech_with_timepoints(ssml_content)

    # Extract timepoints from response
    timepoints = extract_timepoints(response, word_list)

    # Attach audio to message via ActiveStorage using Tempfile to avoid memory bloat
    # (Large MP3s can be 10-20MB, StringIO loads entirely into memory)
    Tempfile.create(['tts_audio', '.mp3'], binmode: true) do |temp_file|
      temp_file.write(response.audio_content)
      temp_file.rewind
      message.audio.attach(
        io: temp_file,
        filename: "message_#{message.id}.mp3",
        content_type: 'audio/mpeg'
      )
    end

    # Store timepoints for text highlighting
    message.update!(tts_timepoints: timepoints)

    # Broadcast completion to flip spinner to media controls
    broadcast_tts_ready(message)
  rescue Google::Cloud::InvalidArgumentError => e
    # Content malformed - don't retry
    Rails.logger.error("TTS invalid content for message #{message_id}: #{e.message}")
    broadcast_tts_unavailable(message)
  rescue Google::Cloud::PermissionDeniedError, Google::Cloud::UnauthenticatedError => e
    # Credential issues - don't retry, needs human intervention
    Rails.logger.error("TTS credential error for message #{message_id}: #{e.message}")
    broadcast_tts_unavailable(message)
  end

  private

  # Converts plain text to SSML with <mark> tags for each word.
  # Returns [ssml_string, word_list] for timepoint mapping.
  #
  # Example:
  #   Input:  "Hello world"
  #   Output: ["<speak><mark name='w0'/>Hello <mark name='w1'/>world</speak>", ["Hello", "world"]]
  #
  def build_ssml_with_marks(text)
    # Strip markdown for cleaner TTS output
    clean_text = strip_markdown(text)

    # Split into words, preserving sentence structure
    words = clean_text.split(/\s+/).compact_blank

    # Build SSML with marks before each word
    ssml_parts = words.each_with_index.map do |word, index|
      "<mark name='w#{index}'/>#{word}"
    end

    ssml = "<speak>#{ssml_parts.join(' ')}</speak>"
    [ssml, words]
  end

  # Basic markdown stripping for cleaner TTS output
  def strip_markdown(text)
    text
      .gsub(/\*\*(.+?)\*\*/m, '\1')      # Bold (asterisk)
      .gsub(/__(.+?)__/m, '\1')          # Bold (underscore)
      .gsub(/\*(.+?)\*/m, '\1')          # Italic (asterisk)
      .gsub(/_(.+?)_/m, '\1')            # Italic (underscore)
      .gsub(/`(.+?)`/, '\1')             # Inline code
      .gsub(/```[\s\S]*?```/, '')        # Code blocks
      .gsub(/^#+\s*/, '')                # Headers
      .gsub(/^\s*[-*]\s+/, '')           # Unordered list items
      .gsub(/^\s*\d+\.\s+/, '')          # Numbered list items
      .gsub(/\[(.+?)\]\(.+?\)/, '\1')    # Links - keep text, remove URL
      .gsub(/\n{2,}/, "\n")              # Multiple newlines to single
      .strip
  end

  # Calls Google Cloud Text-to-Speech API with SSML input and timepoint request
  # Uses v1beta1 API which supports enable_time_pointing for word-level timestamps
  def synthesize_speech_with_timepoints(ssml)
    client = Google::Cloud::TextToSpeech::V1beta1::TextToSpeech::Client.new

    config = Rails.application.config.google_tts

    client.synthesize_speech(
      input: { ssml: ssml },
      voice: config[:voice],
      audio_config: config[:audio_config],
      enable_time_pointing: [:SSML_MARK]
    )
  end

  # Extracts timepoints from TTS response and maps them to word indices
  # Returns array of {word: "text", start_time: seconds} objects
  def extract_timepoints(response, word_list)
    timepoints = response.timepoints.map do |tp|
      # Mark names are like "w0", "w1", etc.
      index = tp.mark_name.sub('w', '').to_i
      {
        word: word_list[index],
        index: index,
        start_time: tp.time_seconds
      }
    end

    timepoints.sort_by { |tp| tp[:index] }
  end

  # Broadcasts Turbo Stream to replace spinner with audio player
  def broadcast_tts_ready(message)
    message.broadcast_replace_to(
      "chat_#{message.chat_id}",
      target: "message_#{message.id}_audio",
      partial: 'messages/audio_player',
      locals: { message: message, just_generated: true }
    )
  end

  # Broadcasts error message when TTS fails
  def broadcast_tts_unavailable(message)
    message.broadcast_replace_to(
      "chat_#{message.chat_id}",
      target: "message_#{message.id}_audio",
      partial: 'messages/audio_error',
      locals: { message: message }
    )
  end
end
