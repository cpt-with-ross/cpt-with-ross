/**
 * =============================================================================
 * SidebarHighlightController - Dynamic Sidebar Active State Management
 * =============================================================================
 *
 * Highlights the sidebar item corresponding to whatever is shown in main_content.
 * Uses MutationObserver to detect content changes from both Turbo Frame loads
 * and Turbo Stream updates.
 *
 * Usage: Add data-controller="sidebar-highlight" to the sidebar container
 *
 * Sidebar items should have data-sidebar-item-path attribute with their path:
 *   data-sidebar-item-path="/index_events/1/baseline"
 *   data-sidebar-item-path="/abc_worksheets/1"
 */
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    this.mainContent = document.getElementById('main_content');
    if (this.mainContent) {
      this.observer = new MutationObserver(() => this.scheduleUpdate());
      this.observer.observe(this.mainContent, { childList: true, subtree: true });
    }

    // Also listen for Turbo Stream renders which may update sidebar items
    this.boundStreamRender = () => this.scheduleUpdate();
    document.addEventListener('turbo:before-stream-render', this.boundStreamRender);

    this.updateHighlights();
  }

  disconnect() {
    this.observer?.disconnect();
    document.removeEventListener('turbo:before-stream-render', this.boundStreamRender);
    if (this.updateTimeout) clearTimeout(this.updateTimeout);
  }

  scheduleUpdate() {
    // Debounce with a small delay to let all Turbo Stream updates complete
    if (this.updateTimeout) clearTimeout(this.updateTimeout);
    this.updateTimeout = setTimeout(() => {
      this.updateTimeout = null;
      this.updateHighlights();
    }, 10);
  }

  updateHighlights() {
    const currentPath = this.getCurrentPath();
    const sidebarItems = this.element.querySelectorAll('[data-sidebar-item-path]');

    sidebarItems.forEach(item => {
      const itemPath = item.dataset.sidebarItemPath;
      const isActive = currentPath && this.pathsMatch(currentPath, itemPath);
      this.updateItemState(item, isActive);
    });
  }

  getCurrentPath() {
    const pathElement = this.mainContent?.querySelector('[data-current-path-path-value]');
    return pathElement?.dataset.currentPathPathValue || null;
  }

  pathsMatch(currentPath, itemPath) {
    if (!currentPath || !itemPath) return false;
    return currentPath.replace(/\/$/, '') === itemPath.replace(/\/$/, '');
  }

  updateItemState(item, isActive) {
    if (item.dataset.controller?.includes('sidebar-toggle')) {
      item.classList.toggle('sidebar-active', isActive);
      item.querySelector('.sidebar-nav-text')?.classList.toggle('fw-bold', isActive);
    } else if (item.tagName === 'A' && item.classList.contains('sidebar-nav-text')) {
      item.classList.toggle('sidebar-active', isActive);
      item.classList.toggle('fw-bold', isActive);
    } else {
      const link = item.querySelector('a.sidebar-nav-text');
      link?.classList.toggle('sidebar-active', isActive);
      link?.classList.toggle('fw-bold', isActive);
    }
  }
}
