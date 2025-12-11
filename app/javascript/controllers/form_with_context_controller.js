/**
 * =============================================================================
 * FormWithContextController - Context Injection for Form Submissions
 * =============================================================================
 *
 * Injects the current main_content path into form submissions as a hidden field.
 * This enables controllers to know what content the user is viewing when they
 * submit a form from the sidebar.
 *
 * Usage: data-controller="form-with-context" data-action="submit->form-with-context#submit"
 */
import { Controller } from '@hotwired/stimulus';
import { injectCurrentPathField } from 'utils/path_utils';

export default class extends Controller {
  submit() {
    injectCurrentPathField(this.element);
  }
}
