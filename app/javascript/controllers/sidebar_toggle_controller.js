/**
 * =============================================================================
 * SidebarToggleController - Index Event Accordion with Smart Navigation
 * =============================================================================
 *
 * Manages the Index Event accordion toggle behavior in the sidebar. The toggle
 * has three-state behavior depending on context:
 *
 * 1. When collapsed -> Expand and navigate to Impact Statement
 * 2. When expanded but NOT viewing Impact Statement -> Navigate to Impact Statement
 * 3. When expanded AND viewing Impact Statement -> Collapse and show welcome
 *
 * This creates an intuitive UX where clicking an Index Event title focuses on
 * that event's content, and clicking again "closes" it.
 *
 * Usage: data-controller="sidebar-toggle"
 *
 * Values:
 * - expandUrl: URL to load when expanding (typically Impact Statement)
 * - collapseUrl: URL to load when collapsing (typically dashboard/welcome)
 * - collapseId: DOM ID of the Bootstrap collapse element
 */
import { Controller } from '@hotwired/stimulus';

/* global bootstrap */

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
      // Create bound handlers that check if event is for our specific collapse
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

      // Sync button state with Bootstrap collapse events
      this.collapseElement.addEventListener('shown.bs.collapse', this.handleShown);
      this.collapseElement.addEventListener('hidden.bs.collapse', this.handleHidden);

      // Set initial state from DOM
      const isExpanded = this.collapseElement.classList.contains('show');
      this.updateButtonState(isExpanded);
    }

    // Track main_content frame URL for determining current view
    document.addEventListener('turbo:frame-load', this.handleFrameLoad);
  }

  disconnect() {
    document.removeEventListener('turbo:frame-load', this.handleFrameLoad);
    if (this.collapseElement) {
      this.collapseElement.removeEventListener('shown.bs.collapse', this.handleShown);
      this.collapseElement.removeEventListener('hidden.bs.collapse', this.handleHidden);
    }
  }

  // Track the current URL in main_content for conditional navigation logic
  handleFrameLoad(event) {
    if (event.target.id === 'main_content') {
      const frame = event.target;
      const path = frame.src ? new URL(frame.src, window.location.origin).pathname : '';
      frame.dataset.currentPath = path;
      if (path) {
        sessionStorage.setItem('mainContentCurrentPath', path);
      }
    }
  }

  // Sync button visual state with collapse state
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

  // Main toggle handler - implements three-state behavior
  toggle(event) {
    event.preventDefault();

    const collapseElement = document.getElementById(this.collapseIdValue);
    const isExpanded = collapseElement?.classList.contains('show');

    if (isExpanded && this.isViewingImpactStatement()) {
      // State 3: Expanded + viewing Impact Statement -> collapse
      this.updateButtonState(false);
      this.collapseDrawer(collapseElement);
      this.navigateFrame(this.collapseUrlValue);
    } else if (isExpanded) {
      // State 2: Expanded but viewing something else -> navigate to Impact Statement
      this.navigateFrame(this.expandUrlValue);
    } else {
      // State 1: Collapsed -> expand and show Impact Statement
      this.updateButtonState(true);
      this.expandDrawer(collapseElement);
      this.navigateFrame(this.expandUrlValue);
    }
  }

  // Check if currently viewing this Index Event's Impact Statement
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

  // Navigate the main_content Turbo Frame to a new URL
  navigateFrame(url) {
    const frame = document.getElementById('main_content');
    if (frame) {
      frame.src = url;
    }
  }
}
