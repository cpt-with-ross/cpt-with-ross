import { Controller } from '@hotwired/stimulus';

/**
 * Column Resize Controller
 *
 * Unified drag-to-resize for sidebar and chat columns.
 * Configurable via Stimulus values for edge, min/max widths, and collapse behavior.
 * Only active on desktop (xl and above, ≥1200px).
 */
export default class extends Controller {
  static targets = ['panel', 'resizeHandle', 'expandBtn'];

  static values = {
    edge: { type: String, default: 'right' },       // 'left' or 'right'
    minWidth: { type: Number, default: 16.666 },    // percentage
    maxWidth: { type: Number, default: 25 },        // percentage
    minWidthPx: { type: Number, default: 0 },       // optional pixel minimum
    collapsible: { type: Boolean, default: false },
    storageKey: { type: String, default: 'column' }
  };

  // Breakpoints (Bootstrap 5)
  static DESKTOP_MIN_WIDTH = 1200; // xl breakpoint

  initialize() {
    this.resize = this.resize.bind(this);
    this.stopResize = this.stopResize.bind(this);
    this.onMediaChange = this.onMediaChange.bind(this);
  }

  connect() {
    // Desktop: xl and above (≥1200px)
    // Mobile: lg and below (<1200px)
    this.desktopQuery = window.matchMedia(`(min-width: ${this.constructor.DESKTOP_MIN_WIDTH}px)`);
    this.desktopQuery.addEventListener('change', this.onMediaChange);
    this.onMediaChange();
  }

  disconnect() {
    this.desktopQuery.removeEventListener('change', this.onMediaChange);
    document.removeEventListener('mousemove', this.resize);
    document.removeEventListener('mouseup', this.stopResize);
  }

  onMediaChange() {
    if (this.isMobile) {
      // Reset to CSS defaults on mobile
      this.panelTarget.classList.remove('collapsed');
      this.panelTarget.style.width = '';
      if (this.hasExpandBtnTarget) this.expandBtnTarget.classList.add('d-none');
    } else {
      this.loadState();
    }
  }

  loadState() {
    if (this.isMobile) return;

    const savedWidth = localStorage.getItem(`${this.storageKeyValue}Width`);
    if (savedWidth) {
      this.panelTarget.style.width = `${savedWidth}%`;
    }

    if (this.collapsibleValue) {
      const collapsed = localStorage.getItem(`${this.storageKeyValue}Collapsed`) === 'true';
      if (collapsed) this.collapse();
    }
  }

  // Resize handling (desktop only)

  startResize(event) {
    if (this.isMobile) return;

    event.preventDefault();
    this.isResizing = true;
    this.startX = event.clientX;
    this.startWidth = this.panelTarget.offsetWidth;

    document.body.classList.add('resizing-active');
    document.addEventListener('mousemove', this.resize);
    document.addEventListener('mouseup', this.stopResize);
  }

  resize(event) {
    if (!this.isResizing || this.isMobile) return;

    const containerWidth = this.getContainerWidth();
    const deltaX = this.edgeValue === 'left'
      ? this.startX - event.clientX
      : event.clientX - this.startX;

    let newWidthPct = ((this.startWidth + deltaX) / containerWidth) * 100;

    // Apply percentage constraints
    newWidthPct = Math.max(this.minWidthValue, Math.min(this.maxWidthValue, newWidthPct));

    // Apply pixel minimum if specified
    if (this.minWidthPxValue > 0) {
      const minPct = (this.minWidthPxValue / containerWidth) * 100;
      newWidthPct = Math.max(minPct, newWidthPct);
    }

    this.panelTarget.style.width = `${newWidthPct}%`;
  }

  stopResize() {
    if (!this.isResizing) return;
    this.isResizing = false;

    document.body.classList.remove('resizing-active');
    document.removeEventListener('mousemove', this.resize);
    document.removeEventListener('mouseup', this.stopResize);

    if (this.isMobile) return;

    const containerWidth = this.getContainerWidth();
    const currentWidth = (this.panelTarget.offsetWidth / containerWidth) * 100;
    localStorage.setItem(`${this.storageKeyValue}Width`, currentWidth.toString());
  }

  getContainerWidth() {
    return this.panelTarget.closest('.d-flex')?.offsetWidth || window.innerWidth;
  }

  // Collapse handling (desktop only, for collapsible panels)

  toggle() {
    if (this.isMobile || !this.collapsibleValue) return;

    const isCollapsed = this.panelTarget.classList.contains('collapsed');
    if (isCollapsed) {
      this.expand();
    } else {
      this.collapse();
    }
    localStorage.setItem(`${this.storageKeyValue}Collapsed`, (!isCollapsed).toString());
  }

  collapse() {
    if (this.isMobile || !this.collapsibleValue) return;
    this.panelTarget.classList.add('collapsed');
    if (this.hasExpandBtnTarget) this.expandBtnTarget.classList.remove('d-none');
  }

  expand() {
    if (this.isMobile || !this.collapsibleValue) return;
    this.panelTarget.classList.remove('collapsed');
    if (this.hasExpandBtnTarget) this.expandBtnTarget.classList.add('d-none');
  }

  // Helpers
  get isDesktop() { return this.desktopQuery.matches; } // xl and above (≥1200px)
  get isMobile() { return !this.isDesktop; } // lg and below (<1200px)
}
