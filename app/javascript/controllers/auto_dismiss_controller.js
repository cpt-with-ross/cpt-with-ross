/**
 * AutoDismissController - Auto-dismiss alerts after 2 seconds
 *
 * Usage: data-controller="auto-dismiss"
 */
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.element.classList.remove('show');
      setTimeout(() => this.element.remove(), 150);
    }, 2000);
  }
}
