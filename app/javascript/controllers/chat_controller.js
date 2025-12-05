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
    this.subscription?.unsubscribe();
    this.observer?.disconnect();
  }

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

  observeMutations() {
    this.observer = new MutationObserver(() => {
      this.scrollToBottom();
    });

    this.observer.observe(this.messagesTarget, {
      childList: true,
      subtree: true,
      characterData: true
    });
  }

  scrollToBottom() {
    requestAnimationFrame(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
    });
  }
}
