/**
 * =============================================================================
 * AudioPlayerController - TTS Audio Playback with Text Highlighting
 * =============================================================================
 *
 * Manages audio playback for TTS-generated message audio. Provides:
 * - Play/pause toggle with icon switching
 * - Rewind to beginning
 * - Time display
 * - Word-level text highlighting synced to audio playback
 * - Integration with AudioManager for exclusive playback
 *
 * The controller preloads audio on connect for instant playback.
 * Text highlighting uses timepoints from Google TTS API to sync words
 * with the audio timeline.
 */
import { Controller } from '@hotwired/stimulus';
import AudioManager from 'utils/audio_manager';
import { isAutoPlayEnabled, AUTOPLAY_ENABLED_EVENT } from 'utils/tts_settings';

export default class extends Controller {
  static values = {
    url: String,
    timepoints: Array,
    messageId: Number,
    justGenerated: Boolean
  };

  static targets = ['playBtn', 'playIcon', 'pauseIcon', 'time'];

  connect() {
    this.audio = null;
    this.isPlaying = false;
    this.currentWordIndex = -1;
    this.autoPlayBlocked = false;

    // Find the output element for text highlighting
    this.outputElement = document.getElementById(`message_${this.messageIdValue}_output`);

    // Listen for autoplay toggle event (fallback if audio was blocked)
    this.boundOnAutoPlayEnabled = this.onAutoPlayEnabled.bind(this);
    window.addEventListener(AUTOPLAY_ENABLED_EVENT, this.boundOnAutoPlayEnabled);

    // Initialize audio if URL is available
    if (this.urlValue) {
      this.initAudio();

      // Auto-play if enabled and this audio was just generated
      if (this.justGeneratedValue && isAutoPlayEnabled()) {
        this.scheduleAutoPlay();
      }
    }
  }

  /**
   * Schedules auto-play after audio is ready
   */
  scheduleAutoPlay() {
    this.autoPlayPending = true;

    const attemptAutoPlay = () => {
      if (!this.autoPlayPending || this.isPlaying) return;
      this.autoPlayPending = false;
      this.togglePlay();
    };

    // Try immediately if audio is ready
    if (this.audio.readyState >= 2) {
      setTimeout(attemptAutoPlay, 100);
    }

    // Also listen for canplay in case it's not ready yet
    this.audio.addEventListener('canplay', () => setTimeout(attemptAutoPlay, 100), { once: true });

    // Fallback: try after a delay in case events were missed
    setTimeout(attemptAutoPlay, 1000);
  }

  disconnect() {
    // Remove window event listener
    window.removeEventListener(AUTOPLAY_ENABLED_EVENT, this.boundOnAutoPlayEnabled);

    // Clean up audio element and its event listeners to prevent memory leaks
    if (this.audio) {
      this.audio.pause();
      this.audio.removeEventListener('play', this.boundOnPlay);
      this.audio.removeEventListener('pause', this.boundOnPause);
      this.audio.removeEventListener('ended', this.boundOnEnded);
      this.audio.removeEventListener('timeupdate', this.boundOnTimeUpdate);
      this.audio.removeEventListener('loadedmetadata', this.boundOnLoadedMetadata);
      this.audio.removeEventListener('error', this.boundOnError);
      this.audio.src = '';
      this.audio = null;
    }

    // Clear from AudioManager if we were the active player
    AudioManager.clear(this);

    // Remove any lingering highlights
    this.clearHighlights();
  }

  /**
   * Called when user enables auto-play via toggle button.
   * The click provides user interaction context for browser autoplay policy.
   * If this player's autoplay was blocked, retry now.
   */
  onAutoPlayEnabled() {
    if (this.autoPlayBlocked && this.justGeneratedValue && !this.isPlaying) {
      this.autoPlayBlocked = false;
      this.togglePlay();
    }
  }

  /**
   * Initializes the HTML5 Audio element with preloading
   */
  initAudio() {
    this.audio = new Audio();
    this.audio.preload = 'auto';
    this.audio.src = this.urlValue;

    // Bind event handlers so they can be removed later
    this.boundOnPlay = () => this.onPlay();
    this.boundOnPause = () => this.onPause();
    this.boundOnEnded = () => this.onEnded();
    this.boundOnTimeUpdate = () => this.onTimeUpdate();
    this.boundOnLoadedMetadata = () => this.onLoadedMetadata();
    this.boundOnError = (e) => this.onError(e);

    // Event listeners for state management
    this.audio.addEventListener('play', this.boundOnPlay);
    this.audio.addEventListener('pause', this.boundOnPause);
    this.audio.addEventListener('ended', this.boundOnEnded);
    this.audio.addEventListener('timeupdate', this.boundOnTimeUpdate);
    this.audio.addEventListener('loadedmetadata', this.boundOnLoadedMetadata);
    this.audio.addEventListener('error', this.boundOnError);
  }

  /**
   * Toggles between play and pause states
   */
  togglePlay() {
    if (!this.audio) return;

    if (this.isPlaying) {
      this.audio.pause();
    } else {
      // Register with AudioManager (stops other players)
      AudioManager.play(this);

      // Wrap words in spans for highlighting if not already done
      this.prepareTextForHighlighting();

      this.audio.play().catch((error) => {
        // Track if blocked by browser autoplay policy
        if (error.name === 'NotAllowedError') {
          this.autoPlayBlocked = true;
        } else {
          console.error('Audio playback failed:', error);
        }
      });
    }
  }

  /**
   * Rewinds audio to the beginning
   */
  rewind() {
    if (!this.audio) return;

    this.audio.currentTime = 0;
    this.currentWordIndex = -1;
    this.clearHighlights();
    this.updateTimeDisplay();
  }

  /**
   * Called by AudioManager when another player starts
   * Stops this player without triggering AudioManager again
   */
  stopFromManager() {
    if (this.audio && this.isPlaying) {
      this.audio.pause();
    }
  }

  // =============================================================================
  // Event Handlers
  // =============================================================================

  onPlay() {
    this.isPlaying = true;
    this.updatePlayButton();
  }

  onPause() {
    this.isPlaying = false;
    this.updatePlayButton();
  }

  onEnded() {
    this.isPlaying = false;
    this.audio.currentTime = 0;
    this.currentWordIndex = -1;
    this.updatePlayButton();
    this.updateTimeDisplay();
    this.clearHighlights();

    // Clear from AudioManager
    AudioManager.clear(this);
  }

  onTimeUpdate() {
    this.updateTimeDisplay();
    this.updateHighlighting();
  }

  onLoadedMetadata() {
    this.updateTimeDisplay();
  }

  onError(event) {
    console.error('Audio loading error:', event);
  }

  // =============================================================================
  // UI Updates
  // =============================================================================

  /**
   * Updates the play/pause button icon based on current state
   */
  updatePlayButton() {
    if (!this.hasPlayIconTarget || !this.hasPauseIconTarget) return;

    if (this.isPlaying) {
      this.playIconTarget.classList.add('d-none');
      this.pauseIconTarget.classList.remove('d-none');
      this.playBtnTarget.title = 'Pause';
    } else {
      this.playIconTarget.classList.remove('d-none');
      this.pauseIconTarget.classList.add('d-none');
      this.playBtnTarget.title = 'Play';
    }
  }

  /**
   * Updates the time display (current time / duration)
   */
  updateTimeDisplay() {
    if (!this.hasTimeTarget || !this.audio) return;

    const current = this.formatTime(this.audio.currentTime);
    const duration =
      this.audio.duration && isFinite(this.audio.duration)
        ? ` / ${this.formatTime(this.audio.duration)}`
        : '';

    this.timeTarget.textContent = `${current}${duration}`;
  }

  /**
   * Formats seconds into M:SS format
   */
  formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  // =============================================================================
  // Text Highlighting
  // =============================================================================

  /**
   * Wraps words in the output element with spans for highlighting.
   * Only runs once per message.
   */
  prepareTextForHighlighting() {
    if (!this.outputElement || this.outputElement.dataset.ttsWrapped === 'true') {
      return;
    }

    // Skip if no timepoints
    if (!this.timepointsValue || this.timepointsValue.length === 0) {
      return;
    }

    // Walk text nodes and wrap words
    this.wrapTextNodes(this.outputElement);
    this.outputElement.dataset.ttsWrapped = 'true';
  }

  /**
   * Recursively wraps text nodes in word spans
   */
  wrapTextNodes(element) {
    const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT, null, false);

    const textNodes = [];
    let node;
    while ((node = walker.nextNode())) {
      if (node.textContent.trim()) {
        textNodes.push(node);
      }
    }

    let wordIndex = 0;
    textNodes.forEach((textNode) => {
      const words = textNode.textContent.split(/(\s+)/);
      const fragment = document.createDocumentFragment();

      words.forEach((part) => {
        if (part.trim()) {
          // It's a word
          const span = document.createElement('span');
          span.className = 'tts-word';
          span.dataset.wordIndex = wordIndex;
          span.textContent = part;
          fragment.appendChild(span);
          wordIndex++;
        } else if (part) {
          // It's whitespace
          fragment.appendChild(document.createTextNode(part));
        }
      });

      textNode.parentNode.replaceChild(fragment, textNode);
    });
  }

  /**
   * Updates word highlighting based on current audio time
   */
  updateHighlighting() {
    if (!this.outputElement || !this.timepointsValue || this.timepointsValue.length === 0) {
      return;
    }

    const currentTime = this.audio.currentTime;

    // Find the current word based on timepoints
    let newIndex = -1;
    for (let i = this.timepointsValue.length - 1; i >= 0; i--) {
      if (currentTime >= this.timepointsValue[i].start_time) {
        newIndex = this.timepointsValue[i].index;
        break;
      }
    }

    // Only update if index changed
    if (newIndex !== this.currentWordIndex) {
      this.highlightWord(newIndex);
      this.currentWordIndex = newIndex;
    }
  }

  /**
   * Highlights the word at the given index
   */
  highlightWord(index) {
    if (!this.outputElement) return;

    // Remove previous highlight
    const previousHighlight = this.outputElement.querySelector('.tts-highlight');
    if (previousHighlight) {
      previousHighlight.classList.remove('tts-highlight');
    }

    // Add new highlight
    if (index >= 0) {
      const wordSpan = this.outputElement.querySelector(`[data-word-index="${index}"]`);
      if (wordSpan) {
        wordSpan.classList.add('tts-highlight');

        // Scroll word into view if needed
        wordSpan.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      }
    }
  }

  /**
   * Removes all word highlights
   */
  clearHighlights() {
    if (!this.outputElement) return;

    const highlighted = this.outputElement.querySelectorAll('.tts-highlight');
    highlighted.forEach((el) => el.classList.remove('tts-highlight'));
  }
}
