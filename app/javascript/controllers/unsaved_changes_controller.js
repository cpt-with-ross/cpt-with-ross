/**
 * UnsavedChangesController - Warns users about unsaved form changes
 *
 * Compares current form values against original values to detect changes.
 * Shows confirmation dialog when navigating away with unsaved changes.
 *
 * Intercepts:
 *   - All Turbo link clicks (uses click tracking to distinguish from hover prefetches)
 *   - Browser navigation (beforeunload)
 *
 * Usage:
 *   <div data-controller="unsaved-changes">
 *     <form>...</form>
 *   </div>
 */
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    this.originalValues = {};
    this.recentLinkClick = false;

    this.handleSubmitEnd = this.handleSubmitEnd.bind(this);
    this.handleBeforeUnload = this.handleBeforeUnload.bind(this);
    this.handleLinkClick = this.handleLinkClick.bind(this);
    this.handleTurboFetch = this.handleTurboFetch.bind(this);

    this.storeOriginalValues();

    this.element.addEventListener('turbo:submit-end', this.handleSubmitEnd);
    window.addEventListener('beforeunload', this.handleBeforeUnload);
    document.addEventListener('click', this.handleLinkClick, true);
    document.addEventListener('turbo:before-fetch-request', this.handleTurboFetch);
  }

  disconnect() {
    this.element.removeEventListener('turbo:submit-end', this.handleSubmitEnd);
    window.removeEventListener('beforeunload', this.handleBeforeUnload);
    document.removeEventListener('click', this.handleLinkClick, true);
    document.removeEventListener('turbo:before-fetch-request', this.handleTurboFetch);
  }

  storeOriginalValues() {
    const form = this.element.querySelector('form');
    if (!form) return;

    this.originalValues = {};
    form.querySelectorAll('input, textarea, select').forEach((input) => {
      const key = input.name || input.id;
      if (!key) return;

      if (input.type === 'radio') {
        if (input.checked) {
          this.originalValues[key] = input.value;
        } else if (!(key in this.originalValues)) {
          this.originalValues[key] = '';
        }
      } else if (input.type === 'checkbox') {
        this.originalValues[key] = input.checked;
      } else {
        this.originalValues[key] = input.value;
      }
    });
  }

  isDirty() {
    const form = this.element.querySelector('form');
    if (!form) return false;

    for (const input of form.querySelectorAll('input, textarea, select')) {
      const key = input.name || input.id;
      if (!key) continue;

      let currentValue;
      if (input.type === 'radio') {
        if (!input.checked) continue;
        currentValue = input.value;
      } else if (input.type === 'checkbox') {
        currentValue = input.checked;
      } else {
        currentValue = input.value;
      }

      if (currentValue !== this.originalValues[key]) {
        return true;
      }
    }
    return false;
  }

  handleSubmitEnd() {
    this.storeOriginalValues();
  }

  handleBeforeUnload(event) {
    if (this.isDirty()) {
      event.preventDefault();
      event.returnValue = 'You have unsaved changes.';
    }
  }

  handleLinkClick(event) {
    if (event.target.closest('a[href]')) {
      this.recentLinkClick = true;
      setTimeout(() => { this.recentLinkClick = false; }, 100);
    }
  }

  handleTurboFetch(event) {
    // Only trigger for user-initiated link clicks, not programmatic navigation
    // (sidebar_toggle_controller handles its own unsaved changes check)
    if (!this.recentLinkClick) return;
    this.recentLinkClick = false;

    const method = (event.detail.fetchOptions.method || 'GET').toUpperCase();
    if (method !== 'GET') return;

    if (!this.isDirty()) return;

    if (!confirm('You have unsaved changes. Are you sure you want to leave? Your changes will be lost.')) {
      event.preventDefault();
    }
  }
}
