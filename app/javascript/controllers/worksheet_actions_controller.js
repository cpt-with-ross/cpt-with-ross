/**
 * WorksheetActionsController - Handle Print, Download, and Email actions for worksheets
 *
 * Manages three actions for ABC Worksheets and Alternative Thoughts:
 * 1. Print: Opens PDF in new window for browser print preview
 * 2. Download: Downloads PDF file directly
 * 3. Email: Sends PDF to user's email address
 */
import { Controller } from '@hotwired/stimulus';

/* global bootstrap */

export default class extends Controller {
  static targets = ['printSelect', 'downloadSelect', 'emailSelect'];

  /**
   * Print action - Opens PDF in new window and triggers browser print dialog
   */
  print(event) {
    event.preventDefault();

    const url = this.printSelectTarget.value;
    if (!url) {
      alert('Please select a worksheet to print.');
      return;
    }

    // Close the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('printModal'));
    if (modal) modal.hide();

    // Add ?print=true parameter to display PDF inline instead of downloading
    const printUrl = url + (url.includes('?') ? '&' : '?') + 'print=true';

    // Open PDF in new window and trigger print when loaded
    const printWindow = window.open(printUrl, '_blank');
    if (printWindow) {
      // Use a timer to ensure PDF is loaded before printing
      printWindow.onload = function() {
        // Small delay to ensure PDF renders
        setTimeout(function() {
          printWindow.print();
        }, 250);
      };
    }
  }

  /**
   * Download action - Downloads PDF file directly
   */
  download(event) {
    event.preventDefault();

    const url = this.downloadSelectTarget.value;
    if (!url) {
      alert('Please select a worksheet to download.');
      return;
    }

    // Close the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('downloadModal'));
    if (modal) modal.hide();

    // Create invisible link and trigger download
    const link = document.createElement('a');
    link.href = url;
    link.download = '';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  /**
   * Email action - Sends PDF to user's email via POST request
   */
  async email(event) {
    event.preventDefault();

    const url = this.emailSelectTarget.value;
    if (!url) {
      alert('Please select a worksheet to email.');
      return;
    }

    // Close the modal
    const modal = bootstrap.Modal.getInstance(document.getElementById('emailModal'));
    if (modal) modal.hide();

    // Show loading state
    this.showNotification('Sending email...', 'info');

    try {
      // Get CSRF token
      const token = document.querySelector('meta[name="csrf-token"]')?.content;

      // Send POST request
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': token,
          'Accept': 'application/json'
        }
      });

      if (response.ok) {
        this.showNotification('Email sent successfully!', 'success');
      } else {
        const data = await response.json();
        this.showNotification(data.error || 'Failed to send email.', 'danger');
      }
    } catch (error) {
      console.error('Email error:', error);
      this.showNotification('An error occurred while sending the email.', 'danger');
    }
  }

  /**
   * Helper: Show Bootstrap toast notification
   */
  showNotification(message, type = 'info') {
    // Create toast container if it doesn't exist
    let toastContainer = document.querySelector('.toast-container');
    if (!toastContainer) {
      toastContainer = document.createElement('div');
      toastContainer.className = 'toast-container position-fixed bottom-0 end-0 p-3';
      document.body.appendChild(toastContainer);
    }

    // Create toast element
    const toastId = `toast-${Date.now()}`;
    const toastHtml = `
      <div id="${toastId}" class="toast" role="alert" aria-live="assertive" aria-atomic="true">
        <div class="toast-header bg-${type} text-white">
          <strong class="me-auto">Notification</strong>
          <button type="button" class="btn-close btn-close-white" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
        <div class="toast-body">
          ${message}
        </div>
      </div>
    `;

    toastContainer.insertAdjacentHTML('beforeend', toastHtml);

    // Show toast
    const toastElement = document.getElementById(toastId);
    const toast = new bootstrap.Toast(toastElement, { autohide: true, delay: 5000 });
    toast.show();

    // Remove toast element after it's hidden
    toastElement.addEventListener('hidden.bs.toast', () => {
      toastElement.remove();
    });
  }
}
