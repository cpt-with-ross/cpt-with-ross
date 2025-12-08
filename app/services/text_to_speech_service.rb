require 'google/cloud/text_to_speech'

class TextToSpeechService
  def initialize
    @client = Google::Cloud::TextToSpeech.text_to_speech
  end

  def synthesize(text:, voice_name: 'en-US-Chirp3-HD-Algenib', language_code: 'en-US')
    input = {
      ssml: "<speak><prosody rate='slow' pitch='-1st' volume='quiet'>#{text}</prosody></speak>"
    }

    voice = {
      language_code: language_code,
      name: voice_name,
    }

    audio_config = {
      audio_encoding: 'MP3',
      speaking_rate: 1.0,
      pitch: 0.0,
    }

    response = @client.synthesize_speech(
      input: input,
      voice: voice,
      audio_config: audio_config
    )

    response.audio_content
  end

  # List available voices for a language
  def list_voices(language_code: nil)
    response = @client.list_voices(language_code: language_code)
    response.voices
  end

#   def generate_tts_audio(message)
#     return if message.content.blank?
#   # 1. Generate the audio data (using a hypothetical TTS service client)
#   # This part is external to Active Storage and requires a specific library/API.
#     audio_content = TextToSpeechService.new.synthesize(text: message.content)

#   # 2. Attach the data using an IO object and a filename
#   # The 'io' needs to be an open IO object (like a StringIO or Tempfile).
#     message.audio.attach(
#       io: StringIO.new(audio_content),
#       filename: "message_#{message.id}_tts.mp3",
#       content_type: 'audio/mp3'
#     )
# end




end

# client = Google::Cloud::TextToSpeech.text_to_speech
# request = ::Google::Cloud::TextToSpeech::V1::ListVoicesRequest.new # (request fields as keyword arguments...)
# response = client.list_voices request


# from google.cloud import texttospeech

# # Instantiates a client
# client = texttospeech.TextToSpeechClient()

# # Set the text input to be synthesized
# synthesis_input = texttospeech.SynthesisInput(text="Hello, World!")

# # Build the voice request, select the language code ("en-US") and the ssml
# # voice gender ("neutral")
# voice = texttospeech.VoiceSelectionParams(
#     language_code="en-US", ssml_gender=texttospeech.SsmlVoiceGender.NEUTRAL
# )

# # Select the type of audio file you want returned
# audio_config = texttospeech.AudioConfig(
#     audio_encoding=texttospeech.AudioEncoding.MP3
# )

# # Perform the text-to-speech request on the text input with the selected
# # voice parameters and audio file type
# response = client.synthesize_speech(
#     input=synthesis_input, voice=voice, audio_config=audio_config
# )

# # The response's audio_content is binary.
# with open("output.mp3", "wb") as out:
#     # Write the response to the output file.
#     out.write(response.audio_content)
#     print('Audio content written to file "output.mp3"')
