/**
 * =============================================================================
 * CurrentPathController - Path Tracking for Main Content
 * =============================================================================
 *
 * Marks the current path of content displayed in main_content. The sidebar
 * highlight controller reads this to determine which sidebar item to highlight.
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
      // Update sessionStorage for form submissions (delete context tracking)
      sessionStorage.setItem('mainContentCurrentPath', this.pathValue);
    }
  }
}
