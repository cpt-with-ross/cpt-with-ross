/**
 * DocumentActionsController - Handle Print and Share actions for documents
 *
 * Manages dropdown actions for CPT documents (ABC Worksheets, Alternative
 * Thoughts, Stuck Points, Baselines).
 *
 * Actions:
 * - Print: Opens PDF in new window for browser print preview
 * - Share: Prompts for email address and sends PDF via email
 */
import { Controller } from '@hotwired/stimulus';

/* global bootstrap */

export default class extends Controller {
  /**
   * Print from dropdown - Opens PDF in new window and triggers print dialog
   */
  printFromDropdown(event) {
    event.preventDefault();
    this._openPrintWindow(event.currentTarget.href);
  }

  /**
   * Share from dropdown - Prompts for email and sends PDF via POST request
   */
  shareFromDropdown(event) {
    event.preventDefault();
    this._showEmailModal(event.currentTarget.href);
  }

  // Private methods

  /**
   * Opens PDF in new window and triggers browser print dialog
   */
  _openPrintWindow(url) {
    const printWindow = window.open(url, '_blank');
    if (printWindow) {
      const triggerPrint = () => {
        if (printWindow.document.readyState === 'complete') {
          printWindow.print();
        } else {
          printWindow.onload = () => printWindow.print();
        }
      };

      // Check if already loaded, otherwise wait for load
      if (printWindow.document.readyState === 'complete') {
        triggerPrint();
      } else {
        printWindow.addEventListener('load', triggerPrint);
      }
    }
  }

  /**
   * Shows Bootstrap modal to collect email address
   * Uses pre-rendered modal from shared/_email_share_modal.html.erb
   */
  _showEmailModal(url) {
    const modalElement = document.getElementById('emailShareModal');
    if (!modalElement) {
      this._showNotification('Email modal not found. Please refresh the page.', 'danger');
      return;
    }

    const modal = new bootstrap.Modal(modalElement);
    const emailInput = document.getElementById('recipientEmail');
    const sendBtn = document.getElementById('sendEmailBtn');

    // Reset modal state
    emailInput.value = '';
    emailInput.classList.remove('is-invalid');
    sendBtn.disabled = false;
    sendBtn.innerHTML = '<i class="fa-solid fa-paper-plane me-1"></i> Send';

    // Clone and replace button to remove old event listeners
    const newSendBtn = sendBtn.cloneNode(true);
    sendBtn.parentNode.replaceChild(newSendBtn, sendBtn);

    // Handle send button click
    newSendBtn.addEventListener('click', async () => {
      const email = emailInput.value.trim();

      if (!email || !this._isValidEmail(email)) {
        emailInput.classList.add('is-invalid');
        return;
      }

      emailInput.classList.remove('is-invalid');
      newSendBtn.disabled = true;
      newSendBtn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span> Sending...';

      modal.hide();
      await this._sendEmail(url, email);
    });

    // Handle enter key in input (use once to avoid stacking listeners)
    const handleEnter = (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        newSendBtn.click();
      }
    };
    emailInput.removeEventListener('keydown', handleEnter);
    emailInput.addEventListener('keydown', handleEnter, { once: false });

    modal.show();
    emailInput.focus();
  }

  /**
   * Validates email format (matches Ruby's URI::MailTo::EMAIL_REGEXP)
   */
  _isValidEmail(email) {
    const emailRegex = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
    return emailRegex.test(email);
  }

  /**
   * Sends PDF to specified email via POST request
   */
  async _sendEmail(url, email) {
    try {
      const token = document.querySelector('meta[name="csrf-token"]')?.content;
      if (!token) {
        this._showNotification('Security token missing. Please refresh the page.', 'danger');
        return;
      }

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': token,
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email: email })
      });

      if (response.ok) {
        this._showNotification('Email sent successfully!', 'success');
      } else {
        const data = await response.json();
        this._showNotification(data.error || 'Failed to send email.', 'danger');
      }
    } catch (error) {
      console.error('Email error:', error);
      this._showNotification('An error occurred while sending the email.', 'danger');
    }
  }

  /**
   * Shows flash alert notification (consistent with Rails flash messages)
   */
  _showNotification(message, type = 'info') {
    // Map notification types to Bootstrap alert classes
    const alertClass = type === 'danger' ? 'alert-warning' : 'alert-primary';

    const alertId = `flash-${Date.now()}`;
    const alertHtml = `
      <div id="${alertId}" class="alert ${alertClass} alert-dismissible fade show m-1" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
      </div>
    `;

    // Find the flash container (after the sticky header in main_content)
    const mainContent = document.getElementById('main_content');
    if (mainContent) {
      mainContent.insertAdjacentHTML('afterbegin', alertHtml);
    } else {
      document.body.insertAdjacentHTML('afterbegin', alertHtml);
    }

    // Auto-dismiss after 2 seconds
    setTimeout(() => {
      const alertElement = document.getElementById(alertId);
      if (alertElement) {
        alertElement.classList.remove('show');
        setTimeout(() => alertElement.remove(), 150);
      }
    }, 2000);
  }
}
