import { Controller } from '@hotwired/stimulus';

/* global bootstrap */

// Handles Index Event sidebar toggle behavior:
// - Click when collapsed: expand and navigate to Impact Statement
// - Click when expanded but not on Impact Statement: navigate to Impact Statement
// - Click when expanded and on Impact Statement: collapse and navigate to dashboard
export default class extends Controller {
  static values = {
    expandUrl: String,
    collapseUrl: String,
    collapseId: String
  };

  initialize() {
    this.handleFrameLoad = this.handleFrameLoad.bind(this);
  }

  connect() {
    this.collapseElement = document.getElementById(this.collapseIdValue);
    if (this.collapseElement) {
      // Bind handlers to check event target matches our specific collapse element
      this.handleShown = (event) => {
        if (event.target === this.collapseElement) {
          this.updateButtonState(true);
        }
      };
      this.handleHidden = (event) => {
        if (event.target === this.collapseElement) {
          this.updateButtonState(false);
        }
      };

      // Listen for Bootstrap collapse events to sync button state
      this.collapseElement.addEventListener('shown.bs.collapse', this.handleShown);
      this.collapseElement.addEventListener('hidden.bs.collapse', this.handleHidden);

      // Set initial state
      const isExpanded = this.collapseElement.classList.contains('show');
      this.updateButtonState(isExpanded);
    }

    // Listen for turbo frame loads to track current URL
    document.addEventListener('turbo:frame-load', this.handleFrameLoad);
  }

  disconnect() {
    document.removeEventListener('turbo:frame-load', this.handleFrameLoad);
    if (this.collapseElement) {
      this.collapseElement.removeEventListener('shown.bs.collapse', this.handleShown);
      this.collapseElement.removeEventListener('hidden.bs.collapse', this.handleHidden);
    }
  }

  handleFrameLoad(event) {
    if (event.target.id === 'main_content') {
      // Store the current URL on the frame element and in sessionStorage
      const frame = event.target;
      const path = frame.src ? new URL(frame.src, window.location.origin).pathname : '';
      frame.dataset.currentPath = path;
      if (path) {
        sessionStorage.setItem('mainContentCurrentPath', path);
      }
    }
  }

  updateButtonState(expanded) {
    const button = this.element.querySelector('button');
    if (button) {
      if (expanded) {
        button.classList.remove('collapsed');
        button.setAttribute('aria-expanded', 'true');
      } else {
        button.classList.add('collapsed');
        button.setAttribute('aria-expanded', 'false');
      }
    }
  }

  toggle(event) {
    event.preventDefault();

    const collapseElement = document.getElementById(this.collapseIdValue);
    const isExpanded = collapseElement?.classList.contains('show');

    if (isExpanded && this.isViewingImpactStatement()) {
      // Collapse and navigate to dashboard
      this.updateButtonState(false);
      this.collapseDrawer(collapseElement);
      this.navigateFrame(this.collapseUrlValue);
    } else if (isExpanded) {
      // Already expanded but not on Impact Statement - just navigate
      this.navigateFrame(this.expandUrlValue);
    } else {
      // Expand and navigate to impact statement
      this.updateButtonState(true);
      this.expandDrawer(collapseElement);
      this.navigateFrame(this.expandUrlValue);
    }
  }

  isViewingImpactStatement() {
    const frame = document.getElementById('main_content');
    const currentPath = frame?.dataset.currentPath || '';
    return currentPath === this.expandUrlValue;
  }

  expandDrawer(collapseElement) {
    const bsCollapse = bootstrap.Collapse.getOrCreateInstance(collapseElement);
    bsCollapse.show();
  }

  collapseDrawer(collapseElement) {
    const bsCollapse = bootstrap.Collapse.getInstance(collapseElement);
    if (bsCollapse) {
      bsCollapse.hide();
    }
  }

  navigateFrame(url) {
    const frame = document.getElementById('main_content');
    if (frame) {
      frame.src = url;
    }
  }
}
