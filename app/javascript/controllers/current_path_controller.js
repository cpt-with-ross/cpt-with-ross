import { Controller } from '@hotwired/stimulus';

// Simple controller that sets the current path in sessionStorage when it connects
// Used in partials rendered via Turbo Streams to track the current view
export default class extends Controller {
  static values = {
    path: String
  };

  connect() {
    if (this.hasPathValue && this.pathValue) {
      sessionStorage.setItem('mainContentCurrentPath', this.pathValue);

      // Also update the frame's dataset for consistency
      const frame = document.getElementById('main_content');
      if (frame) {
        frame.dataset.currentPath = this.pathValue;
      }
    }
  }
}
