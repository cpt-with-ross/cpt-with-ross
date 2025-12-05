import { Controller } from '@hotwired/stimulus';

// Tracks the current path of the main_content frame
// This controller should be attached to the main_content turbo frame
// Stores the path in sessionStorage so it persists across DOM updates
export default class extends Controller {
  static values = {
    initialPath: String
  };

  connect() {
    // Always set path from initial value when controller connects
    // This handles both page loads AND turbo stream updates
    if (this.hasInitialPathValue && this.initialPathValue) {
      this.setCurrentPath(this.initialPathValue);
    }

    this.handleFrameLoad = this.handleFrameLoad.bind(this);
    document.addEventListener('turbo:frame-load', this.handleFrameLoad);
  }

  disconnect() {
    document.removeEventListener('turbo:frame-load', this.handleFrameLoad);
  }

  handleFrameLoad(event) {
    if (event.target.id === 'main_content' && event.target.src) {
      try {
        const path = new URL(event.target.src, window.location.origin).pathname;
        this.setCurrentPath(path);
      } catch {
        // Keep existing path if URL parsing fails
      }
    }
  }

  setCurrentPath(path) {
    sessionStorage.setItem('mainContentCurrentPath', path);
    this.element.dataset.currentPath = path;
  }
}
