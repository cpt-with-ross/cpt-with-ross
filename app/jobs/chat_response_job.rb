# Background job for streaming LLM responses to the UI in real-time.
# Uses RubyLLM's streaming API with ActionCable broadcasts for live updates.
class ChatResponseJob < ApplicationJob
  def perform(chat_id, content)
    chat = Chat.find(chat_id)

    # RubyLLM's #ask method with a block enables streaming mode.
    # Each chunk is a partial response from the LLM as it generates tokens.
    # The assistant message is auto-created by acts_as_chat before streaming begins.
    chat.ask(content) do |chunk|
      if chunk.content.present?
        message = chat.messages.last
        message.broadcast_append_chunk(chunk.content)
      end
    end
  end
end
