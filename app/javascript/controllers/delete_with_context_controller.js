import { Controller } from '@hotwired/stimulus';

// Adds the current main_content frame path to delete forms
// so controllers can conditionally update the center column
export default class extends Controller {
  connect() {
    // Find the form and add submit listener to capture path at submit time
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

  addCurrentPathField(form) {
    // Get current path from sessionStorage (most reliable) or frame dataset
    let currentPath = sessionStorage.getItem('mainContentCurrentPath') || '';

    if (!currentPath) {
      const frame = document.getElementById('main_content');
      currentPath = frame?.dataset.currentPath || '';

      // Fallback to frame src if dataset isn't set
      if (!currentPath && frame?.src) {
        try {
          currentPath = new URL(frame.src, window.location.origin).pathname;
        } catch {
          currentPath = '';
        }
      }
    }

    if (currentPath) {
      // Remove any existing current_path field
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
