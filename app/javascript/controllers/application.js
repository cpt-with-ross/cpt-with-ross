/**
 * =============================================================================
 * Stimulus Application Setup
 * =============================================================================
 *
 * Initializes the Stimulus application and makes it globally available.
 * Controllers are auto-registered via the eagerLoadControllersFrom call in index.js.
 *
 * Debug mode is disabled in production but can be enabled for development
 * to see controller lifecycle events in the console.
 */
import { Application } from '@hotwired/stimulus';

const application = Application.start();

// Set debug: true to see Stimulus logs in browser console
application.debug = false;
window.Stimulus   = application;

export { application };
