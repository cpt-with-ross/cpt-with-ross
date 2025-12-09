/**
 * =============================================================================
 * DeleteWithContextController - Context Injection for Delete Actions
 * =============================================================================
 *
 * Injects the current_path when a delete form is submitted. This enables the
 * "deletion fallback" pattern: when deleting an item the user is viewing,
 * the controller can replace main_content with sensible fallback content.
 *
 * Usage: data-controller="delete-with-context" (on parent of delete form)
 */
import { Controller } from '@hotwired/stimulus';
import { injectCurrentPathField } from '../utils/path_utils';

export default class extends Controller {
  connect() {
    this.form = this.element.querySelector('form');
    if (this.form) {
      this.boundSubmitHandler = (event) => this.handleSubmit(event);
      this.form.addEventListener('submit', this.boundSubmitHandler);
    }
  }

  disconnect() {
    if (this.form && this.boundSubmitHandler) {
      this.form.removeEventListener('submit', this.boundSubmitHandler);
    }
  }

  handleSubmit(event) {
    if (!confirm('Are you sure you want to delete this item?')) {
      event.preventDefault();
      return;
    }
    injectCurrentPathField(this.form);
  }
}
