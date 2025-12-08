import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text"]

  connect() {
    this.audioCache = null
    this.loadAudio()
  }

  async loadAudio() {
    const text = this.textTarget.value || this.textTarget.innerText

    try {
      const response = await fetch('/messages/text_to_speech', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ text: text })
      })

      if (!response.ok) throw new Error('Failed to load audio')

      this.audioCache = await response.blob()
      console.log('Audio loaded and cached')
    } catch (error) {
      console.error('Audio loading error:', error)
    }
  }

  speak(event) {
    event.preventDefault()

    if (!this.audioCache) {
      alert('Audio still loading...')
      return
    }

    const audioUrl = URL.createObjectURL(this.audioCache)
    const audio = new Audio(audioUrl)
    audio.play()
  }
}
