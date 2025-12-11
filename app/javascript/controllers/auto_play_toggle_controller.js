/**
 * AutoPlayToggleController - Manages TTS auto-play preference
 *
 * Simple toggle that persists to localStorage. Defaults to ON (true).
 * Uses shared tts_settings utility for consistent storage access.
 */
import { Controller } from '@hotwired/stimulus';
import {
  isAutoPlayEnabled,
  setAutoPlayEnabled,
  initAutoPlayPreference,
  dispatchAutoPlayEnabled
} from 'utils/tts_settings';

export default class extends Controller {
  static targets = ['slashIcon', 'iconStack'];

  connect() {
    initAutoPlayPreference(true);
    this.updateIcon();
  }

  toggle() {
    const newValue = !isAutoPlayEnabled();
    setAutoPlayEnabled(newValue);
    this.updateIcon();

    // Dispatch event so audio players know autoplay was enabled
    if (newValue) {
      dispatchAutoPlayEnabled();
    }
  }

  updateIcon() {
    if (!this.hasSlashIconTarget || !this.hasIconStackTarget) return;

    if (isAutoPlayEnabled()) {
      this.slashIconTarget.classList.add('d-none');
      this.iconStackTarget.classList.add('text-primary');
      this.element.title = 'Auto-play is ON (click to disable)';
    } else {
      this.slashIconTarget.classList.remove('d-none');
      this.iconStackTarget.classList.remove('text-primary');
      this.element.title = 'Auto-play is OFF (click to enable)';
    }
  }
}
