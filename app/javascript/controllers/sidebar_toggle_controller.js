/**
 * SidebarToggleController - Accordion Toggle with Smart Navigation
 *
 * Manages accordion toggle behavior in the sidebar for Index Events and Stuck Points.
 *
 * Chevron click: Toggle drawer open/close only
 * Title click (Index Events): 3-state behavior:
 *   1. Collapsed -> Expand and navigate to Baseline
 *   2. Expanded but NOT viewing Baseline -> Navigate to Baseline
 *   3. Expanded AND viewing Baseline -> Collapse and show welcome
 * Title click (Stuck Points): Toggle drawer only (no navigation)
 *
 * Uses manual click binding since Stimulus data-action doesn't work reliably
 * on Turbo Stream content. Highlight state is managed by sidebar_highlight_controller.
 */
import { Controller } from '@hotwired/stimulus';

/* global bootstrap */

export default class extends Controller {
  static values = {
    expandUrl: String,
    collapseUrl: String,
    collapseId: String
  };

  connect() {
    this.collapseElement = document.getElementById(this.collapseIdValue);

    // Manual click binding for Turbo Stream compatibility
    this.chevron = this.element.querySelector('.chevron-icon');
    if (this.chevron) {
      this.boundToggleDrawer = (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.toggleDrawer();
      };
      this.chevron.addEventListener('click', this.boundToggleDrawer);
    }

    this.titleText = this.element.querySelector('.sidebar-nav-text') ||
                     this.element.querySelector('span[role="button"]');
    if (this.titleText) {
      this.boundToggle = (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.toggle(e);
      };
      this.titleText.addEventListener('click', this.boundToggle);
    }

    if (this.collapseElement) {
      // Sync chevron state when Bootstrap changes drawer externally
      this.handleShown = (event) => {
        if (event.target === this.collapseElement) {
          this.updateChevronState(true);
        }
      };
      this.handleHidden = (event) => {
        if (event.target === this.collapseElement) {
          this.updateChevronState(false);
        }
      };
      this.collapseElement.addEventListener('shown.bs.collapse', this.handleShown);
      this.collapseElement.addEventListener('hidden.bs.collapse', this.handleHidden);

      const isExpanded = this.collapseElement.classList.contains('show');
      this.updateChevronState(isExpanded);

      // Close other drawers when this one opens (e.g., new Index Event)
      if (isExpanded) {
        setTimeout(() => this.collapseOtherDrawers(), 50);
      }
    }
  }

  disconnect() {
    if (this.chevron && this.boundToggleDrawer) {
      this.chevron.removeEventListener('click', this.boundToggleDrawer);
    }
    if (this.titleText && this.boundToggle) {
      this.titleText.removeEventListener('click', this.boundToggle);
    }
    if (this.collapseElement) {
      this.collapseElement.removeEventListener('shown.bs.collapse', this.handleShown);
      this.collapseElement.removeEventListener('hidden.bs.collapse', this.handleHidden);
    }
  }

  updateChevronState(expanded) {
    this.element.classList.toggle('collapsed', !expanded);
    this.element.setAttribute('aria-expanded', String(expanded));
  }

  toggle(event) {
    event.preventDefault();

    // Debounce duplicate calls from manual binding + data-action
    const now = Date.now();
    if (this._lastToggle && now - this._lastToggle < 100) return;

    const collapseElement = document.getElementById(this.collapseIdValue);
    const isExpanded = collapseElement?.classList.contains('show');

    // Stuck Points: just toggle drawer (no navigation)
    if (!this.hasExpandUrlValue) {
      this._lastToggle = now;
      this.toggleDrawer();
      return;
    }

    // Check for unsaved changes before any state modifications
    if (!this.confirmUnsavedChanges()) return;

    // Update debounce AFTER confirm dialog (dialog blocks, so timer expires)
    this._lastToggle = Date.now();

    // Index Events: 3-state behavior
    if (isExpanded && this.isViewingExpandUrl()) {
      this.updateChevronState(false);
      this.collapseDrawer(collapseElement);
      this.navigateFrame(this.collapseUrlValue);
    } else if (isExpanded) {
      this.navigateFrame(this.expandUrlValue);
    } else {
      this.updateChevronState(true);
      this.expandDrawer(collapseElement);
      this.navigateFrame(this.expandUrlValue);
    }
  }

  toggleDrawer() {
    // Debounce duplicate calls from manual binding + data-action
    const now = Date.now();
    if (this._lastToggleDrawer && now - this._lastToggleDrawer < 100) return;
    this._lastToggleDrawer = now;

    const collapseElement = document.getElementById(this.collapseIdValue);
    if (!collapseElement) return;

    const isExpanded = collapseElement.classList.contains('show');
    if (isExpanded) {
      this.updateChevronState(false);
      this.collapseDrawer(collapseElement);
    } else {
      this.updateChevronState(true);
      this.expandDrawer(collapseElement);
    }
  }

  isViewingExpandUrl() {
    const frame = document.getElementById('main_content');
    if (!frame) return false;

    // Check content's path attribute (works with turbo_stream.update)
    const pathElement = frame.querySelector('[data-current-path-path-value]');
    if (pathElement) {
      return pathElement.dataset.currentPathPathValue === this.expandUrlValue;
    }

    // Fallback: check frame's dataset or src
    const currentPath = frame.dataset.currentPath ||
      (frame.src && new URL(frame.src, window.location.origin).pathname);
    return currentPath === this.expandUrlValue;
  }

  expandDrawer(collapseElement) {
    bootstrap.Collapse.getOrCreateInstance(collapseElement).show();
  }

  collapseDrawer(collapseElement) {
    const bsCollapse = bootstrap.Collapse.getOrCreateInstance(collapseElement);
    // Force shown state for newly created elements (added with .show class via HTML)
    if (!bsCollapse._isShown && collapseElement.classList.contains('show')) {
      bsCollapse._isShown = true;
    }
    bsCollapse.hide();
  }

  navigateFrame(url) {
    const frame = document.getElementById('main_content');
    if (frame) frame.src = url;
  }

  confirmUnsavedChanges() {
    const container = document.querySelector('[data-controller~="unsaved-changes"]');
    if (!container) return true;

    const controller = this.application.getControllerForElementAndIdentifier(
      container,
      'unsaved-changes'
    );
    if (!controller?.isDirty?.()) return true;

    return confirm('You have unsaved changes. Are you sure you want to leave? Your changes will be lost.');
  }

  collapseOtherDrawers() {
    const parent = this.collapseElement?.dataset.bsParent;
    if (!parent) return;

    const accordion = document.querySelector(parent);
    if (!accordion) return;

    accordion.querySelectorAll('.accordion-collapse.show').forEach(collapse => {
      if (collapse !== this.collapseElement) {
        bootstrap.Collapse.getInstance(collapse)?.hide();
      }
    });
  }
}
