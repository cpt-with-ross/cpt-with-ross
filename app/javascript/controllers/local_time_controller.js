/**
 * LocalTimeController - Displays timestamps in the user's local timezone
 *
 * Converts a UTC datetime attribute to the browser's local timezone.
 *
 * Usage:
 *   <time datetime="2025-01-01T12:00:00Z" data-controller="local-time">
 *     Jan 1, 2025 at 12:00 PM
 *   </time>
 */
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    const datetime = this.element.getAttribute('datetime');
    if (!datetime) return;

    const date = new Date(datetime);
    this.element.textContent = date.toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    });
  }
}
