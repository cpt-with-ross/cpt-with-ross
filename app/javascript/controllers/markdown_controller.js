/**
 * =============================================================================
 * MarkdownController - Real-Time Markdown Rendering for Streamed Content
 * =============================================================================
 *
 * Renders markdown content as it streams in via Turbo Streams. Uses a hidden
 * source element (where raw chunks append) and a visible output element
 * (where rendered markdown displays).
 *
 * Usage:
 *   <div data-controller="markdown">
 *     <span data-markdown-target="source" hidden>raw text here</span>
 *     <div data-markdown-target="output"></div>
 *   </div>
 */
import { Controller } from '@hotwired/stimulus';
import { marked } from 'marked';

// Configure marked for safe output
marked.setOptions({
  breaks: true,
  gfm: true
});

export default class extends Controller {
  static targets = ['source', 'output'];

  connect() {
    this.render();
    this.observeSource();
  }

  disconnect() {
    this.observer?.disconnect();
  }

  /**
   * Watches the source element for mutations (new chunks appending).
   * Re-renders markdown to output on each change.
   */
  observeSource() {
    this.observer = new MutationObserver(() => {
      this.render();
    });

    this.observer.observe(this.sourceTarget, {
      childList: true,
      subtree: true,
      characterData: true
    });
  }

  /**
   * Renders the source text content as markdown HTML into the output element.
   */
  render() {
    const raw = this.sourceTarget.textContent || '';
    if (raw.trim()) {
      this.outputTarget.innerHTML = marked.parse(raw);
    } else {
      this.outputTarget.innerHTML = '';
    }
  }
}
