import { Controller } from '@hotwired/stimulus';

/**
 * ConditionalFieldController - Show/hide fields based on radio/select values
 *
 * Usage:
 *   <div data-controller="conditional-field" data-conditional-field-show-value="other">
 *     <input type="radio" value="other">
 *     <div data-conditional-field-target="field" class="d-none">Hidden field</div>
 *   </div>
 */
export default class extends Controller {
  static targets = ['field'];
  static values = { show: String };

  connect() {
    this.check();
    this.element.addEventListener('change', this.check.bind(this));
  }

  disconnect() {
    this.element.removeEventListener('change', this.check.bind(this));
  }

  check() {
    const selected = this.element.querySelector('input[type="radio"]:checked');
    const shouldShow = selected?.value === this.showValue;

    this.fieldTargets.forEach(field => {
      field.classList.toggle('d-none', !shouldShow);
    });
  }
}
