import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['input', 'submit'];

  disable() {
    this.submitTarget.disabled = true;
  }

  reset() {
    this.inputTarget.value = '';
    this.inputTarget.focus();
    this.submitTarget.disabled = false;
  }

  submitOnEnter(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      if (this.inputTarget.value.trim() && !this.submitTarget.disabled) {
        this.element.requestSubmit();
      }
    }
  }
}
