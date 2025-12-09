import { Controller } from '@hotwired/stimulus';

/**
 * Mobile Columns Controller
 *
 * Manages single-column navigation for mobile (lg and below):
 * - Desktop (xl+, ≥1200px): No intervention, 3-column layout
 * - Mobile (sm-lg, 576-1199px): Transform-based swipe navigation
 * - Mobile (xs, <576px): Native scroll with scroll-snap
 */
export default class extends Controller {
  static targets = ['sidebar', 'main', 'chat', 'dots', 'dotSidebar', 'dotMain', 'dotChat', 'navPrev', 'navNext'];

  static DESKTOP_MIN = 1200;
  static SMALL_MAX = 575.98;
  static COLUMN_WIDTH = 576;
  static SWIPE_THRESHOLD = 50;
  static DOTS_DURATION = 1500;

  connect() {
    this.currentColumn = 1;
    this.isDragging = false;

    this.desktopQuery = window.matchMedia(`(min-width: ${this.constructor.DESKTOP_MIN}px)`);
    this.smallQuery = window.matchMedia(`(max-width: ${this.constructor.SMALL_MAX}px)`);

    this.boundUpdate = this.updateMode.bind(this);
    this.desktopQuery.addEventListener('change', this.boundUpdate);
    this.smallQuery.addEventListener('change', this.boundUpdate);

    this.boundFrameLoad = (e) => {
      if (e.target.id === 'main_content' && !this.desktopQuery.matches && this.currentColumn === 0) {
        this.navigateTo(1);
      }
    };
    this.boundResize = () => {
      if (this.mode === 'transform') this.applyTransform(this.currentColumn, false);
      else if (this.mode === 'scroll') this.scrollToColumn(this.currentColumn, false);
    };

    document.addEventListener('turbo:frame-load', this.boundFrameLoad);
    window.addEventListener('resize', this.boundResize);

    this.updateMode();
  }

  disconnect() {
    this.desktopQuery.removeEventListener('change', this.boundUpdate);
    this.smallQuery.removeEventListener('change', this.boundUpdate);
    document.removeEventListener('turbo:frame-load', this.boundFrameLoad);
    window.removeEventListener('resize', this.boundResize);
    this.disableHandlers();
    if (this.dotsTimeout) clearTimeout(this.dotsTimeout);
  }

  updateMode() {
    this.disableHandlers();
    this.resetTransforms();

    if (this.desktopQuery.matches) {
      this.mode = 'desktop';
      this.updateArrows();
      return;
    }

    if (this.smallQuery.matches) {
      this.mode = 'scroll';
      this.boundScroll = this.handleScroll.bind(this);
      this.element.addEventListener('scroll', this.boundScroll, { passive: true });
      this.scrollToColumn(this.currentColumn, false);
    } else {
      this.mode = 'transform';
      this.boundTouchStart = this.handleTouchStart.bind(this);
      this.boundTouchMove = this.handleTouchMove.bind(this);
      this.boundTouchEnd = this.handleTouchEnd.bind(this);
      this.element.addEventListener('touchstart', this.boundTouchStart, { passive: true });
      this.element.addEventListener('touchmove', this.boundTouchMove, { passive: false });
      this.element.addEventListener('touchend', this.boundTouchEnd, { passive: true });
      this.applyTransform(this.currentColumn, false);
    }

    this.updateDots();
  }

  disableHandlers() {
    if (this.boundScroll) this.element.removeEventListener('scroll', this.boundScroll);
    if (this.boundTouchStart) {
      this.element.removeEventListener('touchstart', this.boundTouchStart);
      this.element.removeEventListener('touchmove', this.boundTouchMove);
      this.element.removeEventListener('touchend', this.boundTouchEnd);
    }
  }

  // Scroll mode (xs)
  handleScroll() {
    const newColumn = Math.round(this.element.scrollLeft / this.constructor.COLUMN_WIDTH);
    const colCount = this.hasChatTarget ? 3 : 2;
    if (newColumn !== this.currentColumn && newColumn >= 0 && newColumn < colCount) {
      this.currentColumn = newColumn;
      this.updateDots();
    }
  }

  scrollToColumn(index, animate = true) {
    const target = index * this.constructor.COLUMN_WIDTH;
    if (animate) this.element.scrollTo({ left: target, behavior: 'smooth' });
    else this.element.scrollLeft = target;
    this.currentColumn = index;
  }

  // Transform mode (sm-lg)
  handleTouchStart(e) {
    const touch = e.touches[0];
    this.touchStartX = touch.clientX;
    this.touchStartY = touch.clientY;
    this.isDragging = false;
    this.gestureDecided = false;
    this.getColumns().forEach(col => col.style.transition = 'none');
  }

  handleTouchMove(e) {
    const touch = e.touches[0];
    const deltaX = touch.clientX - this.touchStartX;
    const deltaY = touch.clientY - this.touchStartY;

    if (this.gestureDecided) {
      if (this.isDragging) this.applyDrag(e, deltaX);
      return;
    }

    if (Math.abs(deltaY) > 10 && Math.abs(deltaY) > Math.abs(deltaX)) {
      this.gestureDecided = true;
      return;
    }

    if (Math.abs(deltaX) > 10 && Math.abs(deltaX) > Math.abs(deltaY)) {
      this.gestureDecided = true;
      this.isDragging = true;
      this.applyDrag(e, deltaX);
    }
  }

  applyDrag(e, deltaX) {
    e.preventDefault();
    const colCount = this.hasChatTarget ? 3 : 2;

    if ((this.currentColumn === 0 && deltaX > 0) ||
        (this.currentColumn === colCount - 1 && deltaX < 0)) {
      deltaX *= 0.3;
    }

    const offset = -this.currentColumn * this.element.offsetWidth + deltaX;
    this.getColumns().forEach(col => col.style.transform = `translateX(${offset}px)`);
  }

  handleTouchEnd(e) {
    this.getColumns().forEach(col => col.style.transition = '');
    if (!this.isDragging) return;

    const deltaX = e.changedTouches[0].clientX - this.touchStartX;
    const colCount = this.hasChatTarget ? 3 : 2;
    let newColumn = this.currentColumn;

    if (deltaX < -this.constructor.SWIPE_THRESHOLD && this.currentColumn < colCount - 1) newColumn++;
    else if (deltaX > this.constructor.SWIPE_THRESHOLD && this.currentColumn > 0) newColumn--;

    this.applyTransform(newColumn, true);
    this.isDragging = false;
  }

  applyTransform(index, animate = true) {
    this.currentColumn = index;
    const offset = -index * this.element.offsetWidth;
    const cols = this.getColumns();

    if (!animate) cols.forEach(col => col.style.transition = 'none');
    cols.forEach(col => col.style.transform = `translateX(${offset}px)`);

    if (!animate) {
      this.element.offsetHeight; // Force reflow
      cols.forEach(col => col.style.transition = '');
    }

    this.updateDots();
  }

  resetTransforms() {
    this.getColumns().forEach(col => {
      col.style.transform = '';
      col.style.transition = '';
    });
  }

  getColumns() {
    const cols = [this.sidebarTarget, this.mainTarget];
    if (this.hasChatTarget) cols.push(this.chatTarget);
    return cols;
  }

  // Navigation
  navigateTo(index) {
    if (this.mode === 'scroll') this.scrollToColumn(index);
    else if (this.mode === 'transform') this.applyTransform(index);
    this.updateDots();
  }

  goToSidebar() { if (!this.desktopQuery.matches) this.navigateTo(0); }
  goToMain() { if (!this.desktopQuery.matches) this.navigateTo(1); }
  goToChat() { if (!this.desktopQuery.matches && this.hasChatTarget) this.navigateTo(2); }
  goToPrev() { if (!this.desktopQuery.matches && this.currentColumn > 0) this.navigateTo(this.currentColumn - 1); }
  goToNext() {
    const colCount = this.hasChatTarget ? 3 : 2;
    if (!this.desktopQuery.matches && this.currentColumn < colCount - 1) this.navigateTo(this.currentColumn + 1);
  }

  // UI updates
  updateDots() {
    if (!this.hasDotsTarget) return;

    [this.dotSidebarTarget, this.dotMainTarget, this.dotChatTarget].forEach((dot, i) => {
      if (dot) dot.classList.toggle('active', i === this.currentColumn);
    });

    this.updateArrows();
    this.flashDots();
  }

  flashDots() {
    if (!this.hasDotsTarget || this.desktopQuery.matches) return;

    if (this.dotsTimeout) clearTimeout(this.dotsTimeout);
    this.dotsTarget.classList.add('visible');
    this.dotsTimeout = setTimeout(() => this.dotsTarget.classList.remove('visible'), this.constructor.DOTS_DURATION);
  }

  updateArrows() {
    const colCount = this.hasChatTarget ? 3 : 2;
    const isDesktop = this.desktopQuery.matches;

    if (this.hasNavPrevTarget) this.navPrevTarget.classList.toggle('d-none', isDesktop || this.currentColumn === 0);
    if (this.hasNavNextTarget) this.navNextTarget.classList.toggle('d-none', isDesktop || this.currentColumn >= colCount - 1);
  }
}
