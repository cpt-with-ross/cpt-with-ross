/**
 * =============================================================================
 * CurrentPathController - Path Tracking for Turbo Stream Updates
 * =============================================================================
 *
 * A lightweight controller that updates the tracked current path when content
 * is rendered. Used in partials that are delivered via Turbo Streams to ensure
 * path tracking stays synchronized.
 *
 * This complements FrameTrackerController:
 * - FrameTrackerController: Tracks navigations via frame src changes
 * - CurrentPathController: Tracks updates via Turbo Stream rendering
 *
 * Usage: data-controller="current-path" data-current-path-path-value="/some/path"
 */
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = {
    path: String
  };

  connect() {
    if (this.hasPathValue && this.pathValue) {
      // Update sessionStorage for form submissions
      sessionStorage.setItem('mainContentCurrentPath', this.pathValue);

      // Update frame dataset for consistency with other tracking methods
      const frame = document.getElementById('main_content');
      if (frame) {
        frame.dataset.currentPath = this.pathValue;
      }
    }
  }
}
