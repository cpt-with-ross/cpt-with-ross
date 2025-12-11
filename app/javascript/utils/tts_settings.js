/**
 * TTS Settings - Shared utilities for Text-to-Speech feature
 *
 * Centralizes storage keys, events, and preference management
 * to avoid duplication across TTS-related controllers.
 */

// Storage keys
const AUTOPLAY_KEY = 'ttsAutoPlay';
const AUDIO_UNLOCKED_KEY = 'ttsAudioUnlocked';

// Custom events
const AUTOPLAY_ENABLED_EVENT = 'tts:autoplay-enabled';

/**
 * Check if TTS autoplay is enabled (defaults to true)
 */
export function isAutoPlayEnabled() {
  return localStorage.getItem(AUTOPLAY_KEY) !== 'false';
}

/**
 * Set the autoplay preference
 * @param {boolean} enabled - Whether autoplay should be enabled
 */
export function setAutoPlayEnabled(enabled) {
  localStorage.setItem(AUTOPLAY_KEY, enabled);
}

/**
 * Initialize autoplay preference with default if not set
 * @param {boolean} defaultValue - Default value if not already set
 */
export function initAutoPlayPreference(defaultValue = true) {
  if (localStorage.getItem(AUTOPLAY_KEY) === null) {
    localStorage.setItem(AUTOPLAY_KEY, defaultValue);
  }
}

/**
 * Check if browser audio has been unlocked this session
 */
export function isAudioUnlocked() {
  return sessionStorage.getItem(AUDIO_UNLOCKED_KEY) === 'true';
}

/**
 * Mark browser audio as unlocked for this session
 */
export function setAudioUnlocked() {
  sessionStorage.setItem(AUDIO_UNLOCKED_KEY, 'true');
}

/**
 * Dispatch the autoplay enabled event
 */
export function dispatchAutoPlayEnabled() {
  window.dispatchEvent(new CustomEvent(AUTOPLAY_ENABLED_EVENT));
}

export { AUTOPLAY_KEY, AUDIO_UNLOCKED_KEY, AUTOPLAY_ENABLED_EVENT };
