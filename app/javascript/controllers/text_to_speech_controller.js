import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "playPause", "loading"]

  connect() {
    this.audioCache = null
    this.showLoading()
    this.loadAudio()
  }

  async loadAudio() {
    const text = this.textTarget.value || this.textTarget.innerText
    const cacheKey = `tts-audio-${this.hashText(text)}`
    const etagKey = `tts-etag-${this.hashText(text)}`

    // Check if we have cached audio in memory or localStorage
    const cachedEtag = localStorage.getItem(etagKey)
    const cachedAudio = localStorage.getItem(cacheKey)

    if (cachedAudio) {
      console.log('Using cached audio from localStorage')
      // Convert base64 back to blob
      const binaryString = atob(cachedAudio)
      const bytes = new Uint8Array(binaryString.length)
      for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i)
      }
      this.audioCache = new Blob([bytes], { type: 'audio/mpeg' })
      this.showReady()
      return
    }

    try {
      const headers = {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }

      // Add If-None-Match header if we have a cached ETag
      if (cachedEtag) {
        headers['If-None-Match'] = cachedEtag
      }

      const response = await fetch('/messages/text_to_speech', {
        method: 'POST',
        headers: headers,
        body: JSON.stringify({ text: text })
      })

      // If 304 Not Modified, use existing cache
      if (response.status === 304) {
        console.log('Server returned 304 - using cached audio')
        this.showReady()
        return
      }

      if (!response.ok) throw new Error('Failed to load audio')

      this.audioCache = await response.blob()
      
      // Store ETag for future requests
      const etag = response.headers.get('ETag')
      if (etag) {
        localStorage.setItem(etagKey, etag)
      }

      // Store audio in localStorage as base64
      const reader = new FileReader()
      reader.onloadend = () => {
        const base64 = reader.result.split(',')[1]
        try {
          localStorage.setItem(cacheKey, base64)
          console.log('Audio cached in localStorage')
        } catch (e) {
          console.warn('Could not cache audio in localStorage (quota exceeded?)', e)
        }
      }
      reader.readAsDataURL(this.audioCache)

      console.log('Audio loaded from API and cached')
      this.showReady()
    } catch (error) {
      console.error('Audio loading error:', error)
      this.showError()
    }
  }

  hashText(text) {
    // Simple hash function for cache key
    let hash = 0
    for (let i = 0; i < text.length; i++) {
      const char = text.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash
    }
    return Math.abs(hash).toString(36)
  }

  speak(event) {
    event.preventDefault()

    // Check if audio is loaded
    if (!this.audioCache) {
      console.log('Audio not ready yet')
      return
    }

    // If audio exists and is playing, pause it
    if (this.audio && !this.audio.paused) {
      this.audio.pause()
      this.playPauseTarget.textContent = '▶️'
      return
    }

    // If audio exists and is paused, resume it
    if (this.audio && this.audio.paused && this.audio.currentTime > 0 && !this.audio.ended) {
      this.audio.play()
      this.playPauseTarget.textContent = '⏸️'
      return
    }

    // Create new audio if it doesn't exist or has ended
    const audioUrl = URL.createObjectURL(this.audioCache)
    this.audio = new Audio(audioUrl)

    // Change button to pause icon when playing starts
    this.playPauseTarget.textContent = '⏸️'

    // Play the audio
    this.audio.play()

    // When audio finishes, change button back to play icon
    this.audio.addEventListener('ended', () => {
      this.playPauseTarget.textContent = '▶️'
    })
  }

  showLoading() {
    // Show loading indicator, hide play button
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('d-none')
    }
    if (this.hasPlayPauseTarget) {
      this.playPauseTarget.classList.add('d-none')
    }
  }

  showReady() {
    // Hide loading, show play button - audio is cached and ready
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('d-none')
    }
    if (this.hasPlayPauseTarget) {
      this.playPauseTarget.classList.remove('d-none')
      this.playPauseTarget.textContent = '▶️'
    }
  }

  showError() {
    // Hide loading on error
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('d-none')
    }
    if (this.hasPlayPauseTarget) {
      this.playPauseTarget.classList.add('d-none')
    }
  }

  disconnect() {
    // Cleanup when controller is removed
    if (this.audio) {
      this.audio.pause()
      this.audio = null
    }
  }
}
