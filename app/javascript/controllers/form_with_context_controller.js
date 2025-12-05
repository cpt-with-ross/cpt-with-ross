import { Controller } from '@hotwired/stimulus';

// Adds the current main_content frame path to form submissions
// so controllers can conditionally update the center column
export default class extends Controller {
  submit() {
    const frame = document.getElementById('main_content');
    let currentPath = frame?.dataset.currentPath || '';

    // Fallback to frame src if dataset isn't set
    if (!currentPath && frame?.src) {
      try {
        currentPath = new URL(frame.src, window.location.origin).pathname;
      } catch {
        currentPath = '';
      }
    }

    // Add hidden field with current path to the form
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
