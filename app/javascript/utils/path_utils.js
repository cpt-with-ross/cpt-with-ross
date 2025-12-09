/**
 * Utility functions for path resolution across Stimulus controllers.
 */

/**
 * Gets the current main_content path from sessionStorage or frame src.
 * Used by form controllers to inject context into submissions.
 */
export function getCurrentPath() {
  let path = sessionStorage.getItem('mainContentCurrentPath') || '';

  if (!path) {
    const frame = document.getElementById('main_content');
    if (frame?.src) {
      try {
        path = new URL(frame.src, window.location.origin).pathname;
      } catch {
        path = '';
      }
    }
  }

  return path;
}

/**
 * Injects or updates a hidden current_path field in a form.
 */
export function injectCurrentPathField(form) {
  const currentPath = getCurrentPath();
  if (!currentPath) return;

  let hiddenField = form.querySelector('input[name="current_path"]');
  if (!hiddenField) {
    hiddenField = document.createElement('input');
    hiddenField.type = 'hidden';
    hiddenField.name = 'current_path';
    form.appendChild(hiddenField);
  }
  hiddenField.value = currentPath;
}
