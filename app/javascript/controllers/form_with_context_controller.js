/**
 * =============================================================================
 * FormWithContextController - Context Injection for Form Submissions
 * =============================================================================
 *
 * Injects the current main_content path into form submissions as a hidden field.
 * This enables controllers to know what content the user is viewing when they
 * submit a form from the sidebar.
 *
 * Use case: When updating an IndexEvent title, the controller checks if the
 * user is viewing that event's content and refreshes it if needed.
 *
 * Usage: data-controller="form-with-context" data-action="submit->form-with-context#submit"
 */
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  // Called on form submit - adds current_path hidden field
  submit() {
    const frame = document.getElementById('main_content');
    let currentPath = frame?.dataset.currentPath || '';

    // Fallback to frame src if dataset isn't available
    if (!currentPath && frame?.src) {
      try {
        currentPath = new URL(frame.src, window.location.origin).pathname;
      } catch {
        currentPath = '';
      }
    }

    // Inject or update the hidden field with the current path
    if (currentPath) {
      const form = this.element;
      let hiddenField = form.querySelector('input[name="current_path"]');
      if (!hiddenField) {
        hiddenField = document.createElement('input');
        hiddenField.type = 'hidden';
        hiddenField.name = 'current_path';
        form.appendChild(hiddenField);
      }
      hiddenField.value = currentPath;
    }
  }
}
