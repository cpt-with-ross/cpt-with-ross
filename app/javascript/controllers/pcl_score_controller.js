/**
 * PclScoreController - Real-time PCL-5 Total Score Calculator
 *
 * Calculates and displays the total PCL-5 score as radio buttons are selected.
 * Listens to change events on radio inputs within the controller scope.
 *
 * Usage:
 *   <div data-controller="pcl-score">
 *     <input type="radio" name="pcl_1" value="0" data-pcl-score-target="radio">
 *     ...
 *     <span data-pcl-score-target="total">0</span>
 *   </div>
 */
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['total'];

  connect() {
    this.calculate();
  }

  calculate() {
    const radios = this.element.querySelectorAll('input[type="radio"]:checked');
    let total = 0;

    radios.forEach((radio) => {
      total += parseInt(radio.value, 10) || 0;
    });

    if (this.hasTotalTarget) {
      this.totalTarget.textContent = total;
    }
  }
}
