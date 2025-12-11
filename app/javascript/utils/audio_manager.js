/**
 * =============================================================================
 * AudioManager - Singleton for Exclusive Audio Playback
 * =============================================================================
 *
 * Ensures only one audio player is active at a time. When a new audio player
 * starts playing, any currently playing audio is automatically stopped.
 *
 * This prevents multiple TTS audio streams from playing simultaneously,
 * which would be confusing in a chat interface.
 *
 * Usage:
 *   import AudioManager from 'utils/audio_manager';
 *
 *   // When starting playback:
 *   AudioManager.play(this);  // 'this' is the controller instance
 *
 *   // When stopping playback:
 *   AudioManager.clear(this);  // Clear if this controller was active
 */

class AudioManager {
  static currentController = null;

  /**
   * Registers a controller as the active audio player.
   * Stops any previously playing controller first.
   *
   * @param {Object} controller - The Stimulus controller starting playback
   */
  static play(controller) {
    // Stop the previous controller if different from current
    if (this.currentController && this.currentController !== controller) {
      this.currentController.stopFromManager();
    }

    this.currentController = controller;
  }

  /**
   * Clears the current controller reference.
   * Call this when a controller stops playing.
   *
   * @param {Object} controller - The controller that stopped
   */
  static clear(controller) {
    if (this.currentController === controller) {
      this.currentController = null;
    }
  }
}

export default AudioManager;
