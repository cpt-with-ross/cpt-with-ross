/**
 * =============================================================================
 * FrameTrackerController - Turbo Frame URL Tracking
 * =============================================================================
 *
 * Tracks the current URL loaded in the main_content Turbo Frame. This is
 * crucial for the "current_path" functionality that allows controllers to
 * know what content the user is viewing when they submit forms.
 *
 * Why is this needed?
 * In a Turbo Frame-based SPA, the browser URL doesn't change when frame
 * content loads. We need to track the frame's current URL separately to:
 * - Know if user is viewing content that will be affected by an update
 * - Provide fallback content when deleting the currently-viewed item
 *
 * The path is stored in both sessionStorage and as a data attribute for
 * reliability across different access patterns.
 *
 * Usage: data-controller="frame-tracker" data-frame-tracker-initial-path-value="/path"
 */
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    initialPath: String
  };

  connect() {
    // Set initial path from server-rendered value (handles both page loads
    // and Turbo Stream updates that re-render the frame tracker)
    if (this.hasInitialPathValue && this.initialPathValue) {
      this.setCurrentPath(this.initialPathValue);
    }

    this.handleFrameLoad = this.handleFrameLoad.bind(this);
    document.addEventListener('turbo:frame-load', this.handleFrameLoad);
  }

  disconnect() {
    document.removeEventListener('turbo:frame-load', this.handleFrameLoad);
  }

  // Update tracked path when main_content frame navigates
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

  // Store path in multiple locations for reliable access
  setCurrentPath(path) {
    sessionStorage.setItem('mainContentCurrentPath', path);
    this.element.dataset.currentPath = path;
  }
}
