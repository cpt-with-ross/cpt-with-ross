class GenerateTtsAudioJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find(message_id)
    return if message.audio.attached?

    audio_content = TextToSpeechService.new.synthesize(text: message.content)

    message.audio.attach(
      io: StringIO.new(audio_content),
      filename: "message_#{message.id}.mp3",
      content_type: "audio/mpeg"
    )
  end
end
