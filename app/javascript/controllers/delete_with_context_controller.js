/**
 * =============================================================================
 * DeleteWithContextController - Context Injection for Delete Actions
 * =============================================================================
 *
 * Similar to FormWithContextController but designed for delete button forms.
 * Automatically injects the current_path when the delete form is submitted.
 *
 * This enables the "deletion fallback" pattern: when deleting an item the user
 * is currently viewing, the controller can replace main_content with sensible
 * fallback content (like the impact statement or welcome screen).
 *
 * Differs from FormWithContextController:
 * - Wraps a container element that contains the form
 * - Uses sessionStorage as primary source (more reliable for delete forms)
 * - Attaches listener in connect() rather than via data-action
 *
 * Usage: data-controller="delete-with-context" (on parent of delete form)
 */
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    // Find nested form and attach submit listener
    const form = this.element.querySelector('form');
    if (form) {
      this.boundAddCurrentPath = this.addCurrentPathField.bind(this, form);
      form.addEventListener('submit', this.boundAddCurrentPath);
    }
  }

  disconnect() {
    const form = this.element.querySelector('form');
    if (form && this.boundAddCurrentPath) {
      form.removeEventListener('submit', this.boundAddCurrentPath);
    }
  }

  // Inject current_path hidden field at submit time
  addCurrentPathField(form) {
    // Try sessionStorage first (most reliable across DOM updates)
    let currentPath = sessionStorage.getItem('mainContentCurrentPath') || '';

    // Fallback to frame dataset or src
    if (!currentPath) {
      const frame = document.getElementById('main_content');
      currentPath = frame?.dataset.currentPath || '';

      if (!currentPath && frame?.src) {
        try {
          currentPath = new URL(frame.src, window.location.origin).pathname;
        } catch {
          currentPath = '';
        }
      }
    }

    if (currentPath) {
      // Replace any existing field to ensure fresh value
      const existing = form.querySelector('input[name="current_path"]');
      if (existing) existing.remove();

      const hiddenField = document.createElement('input');
      hiddenField.type = 'hidden';
      hiddenField.name = 'current_path';
      hiddenField.value = currentPath;
      form.appendChild(hiddenField);
    }
  }
}
