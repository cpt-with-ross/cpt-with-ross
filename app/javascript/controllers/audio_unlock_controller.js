/**
 * AudioUnlockController - Silently unlock browser audio on first interaction
 *
 * Browsers require user interaction before allowing audio playback.
 * This controller listens for the first click or keypress and plays
 * a tiny silent audio clip to "unlock" audio for the page session.
 *
 * This is invisible to users and enables seamless TTS autoplay.
 * Attach to body or a high-level container element.
 */
import { Controller } from '@hotwired/stimulus';
import { isAudioUnlocked, setAudioUnlocked } from 'utils/tts_settings';

// Tiny silent WAV file as base64 data URI (44 bytes)
const SILENT_AUDIO = 'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA';

export default class extends Controller {
  connect() {
    // Already unlocked this session
    if (isAudioUnlocked()) {
      return;
    }

    // Bind handlers so we can remove them later
    this.boundUnlock = this.unlock.bind(this);

    // Listen for first interaction
    document.addEventListener('click', this.boundUnlock, { once: true, capture: true });
    document.addEventListener('keydown', this.boundUnlock, { once: true, capture: true });
  }

  disconnect() {
    document.removeEventListener('click', this.boundUnlock, { capture: true });
    document.removeEventListener('keydown', this.boundUnlock, { capture: true });
  }

  unlock() {
    // Remove the other listener
    document.removeEventListener('click', this.boundUnlock, { capture: true });
    document.removeEventListener('keydown', this.boundUnlock, { capture: true });

    // Play silent audio to unlock
    const audio = new Audio(SILENT_AUDIO);
    audio.volume = 0;
    audio.play()
      .then(() => {
        setAudioUnlocked();
      })
      .catch(() => {
        // Silent fail - browser may still be blocking, will retry on next interaction
      });
  }
}
