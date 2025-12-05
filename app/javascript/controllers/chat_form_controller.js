/**
 * =============================================================================
 * ChatFormController - Chat Message Form UX Enhancements
 * =============================================================================
 *
 * Manages the chat input form for better UX:
 * - Disables submit button during submission to prevent double-submit
 * - Clears and re-focuses input after successful submission
 * - Enables Enter key submission (Shift+Enter for newlines)
 *
 * Usage: data-controller="chat-form"
 *
 * Targets:
 * - input: The textarea/input element
 * - submit: The submit button
 *
 * Actions:
 * - disable: Call on form submit to disable button
 * - reset: Call after Turbo Stream response to clear form
 * - submitOnEnter: Bind to keydown on input
 */
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['input', 'submit'];

  // Disable submit button to prevent double-submission
  disable() {
    this.submitTarget.disabled = true;
  }

  // Reset form after successful submission (called via Turbo Stream)
  reset() {
    this.inputTarget.value = '';
    this.inputTarget.focus();
    this.submitTarget.disabled = false;
  }

  // Allow Enter to submit, Shift+Enter for newlines
  submitOnEnter(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      if (this.inputTarget.value.trim() && !this.submitTarget.disabled) {
        this.element.requestSubmit();
      }
    }
  }
}
