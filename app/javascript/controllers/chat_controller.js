/**
 * =============================================================================
 * ChatController - AI Chat Interface with Real-Time Streaming
 * =============================================================================
 *
 * Manages the chat UI for interacting with the AI therapist "Ross". Handles:
 * 1. ActionCable subscription for receiving streamed AI responses
 * 2. Auto-scrolling as new messages/content arrive
 * 3. DOM mutation observation for Turbo Stream updates
 *
 * Usage: data-controller="chat" data-chat-chat-id-value="123"
 *
 * Targets:
 * - messages: The scrollable container holding chat messages
 *
 * Values:
 * - chatId: The Chat record ID to subscribe to via ActionCable
 */
import { Controller } from '@hotwired/stimulus';
import { createConsumer } from '@rails/actioncable';

export default class extends Controller {
  static values = { chatId: Number };
  static targets = ['messages'];

  connect() {
    this.scrollToBottom();
    this.subscribeToChat();
    this.observeMutations();
  }

  disconnect() {
    // Clean up subscriptions and observers to prevent memory leaks
    this.subscription?.unsubscribe();
    this.observer?.disconnect();
  }

  /**
   * Subscribes to the ChatChannel for this specific chat.
   * ActionCable broadcasts from ChatResponseJob trigger scrollToBottom
   * when new content arrives via Turbo Streams.
   */
  subscribeToChat() {
    if (!this.chatIdValue) return;

    const consumer = createConsumer();
    this.subscription = consumer.subscriptions.create(
      { channel: 'ChatChannel', chat_id: this.chatIdValue },
      {
        received: () => {
          this.scrollToBottom();
        }
      }
    );
  }

  /**
   * Observes DOM mutations in the messages container.
   * This catches Turbo Stream updates (new messages, streaming content)
   * that might not trigger ActionCable callbacks directly.
   */
  observeMutations() {
    this.observer = new MutationObserver(() => {
      this.scrollToBottom();
    });

    this.observer.observe(this.messagesTarget, {
      childList: true,   // New messages added
      subtree: true,     // Changes to nested elements
      characterData: true // Text content changes (streaming)
    });
  }

  /**
   * Scrolls the messages container to the bottom.
   * Uses requestAnimationFrame to ensure scroll happens after DOM updates.
   */
  scrollToBottom() {
    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
    });
  }
}
