import { Controller } from '@hotwired/stimulus';

/**
 * Updates the intensity badge as the slider is dragged.
 * Badge turns primary (blue) when intensity > 0.
 */
export default class extends Controller {
  static targets = ['slider', 'badge'];

  updateBadge() {
    const value = this.sliderTarget.value;
    this.badgeTarget.textContent = value;

    if (parseInt(value, 10) > 0) {
      this.badgeTarget.classList.remove('bg-secondary');
      this.badgeTarget.classList.add('bg-primary');
    } else {
      this.badgeTarget.classList.remove('bg-primary');
      this.badgeTarget.classList.add('bg-secondary');
    }
  }
}
