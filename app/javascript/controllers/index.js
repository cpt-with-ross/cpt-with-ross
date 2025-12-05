/**
 * =============================================================================
 * Stimulus Controller Auto-Registration
 * =============================================================================
 *
 * Automatically discovers and registers all Stimulus controllers in the
 * controllers/ directory. Controllers are named based on their filename:
 * - chat_controller.js -> "chat"
 * - sidebar_toggle_controller.js -> "sidebar-toggle"
 *
 * Uses the @hotwired/stimulus-loading package for eager loading, which means
 * all controllers are loaded on initial page load rather than lazily.
 */
import { application } from 'controllers/application';
import { eagerLoadControllersFrom } from '@hotwired/stimulus-loading';
eagerLoadControllersFrom('controllers', application);
