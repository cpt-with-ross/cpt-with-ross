# frozen_string_literal: true

# =============================================================================
# Exportable - Shared controller logic for PDF export, print, and email sharing
# =============================================================================
#
# Provides `export` and `share` actions for controllers that support PDF export
# and email sharing functionality.
#
# Usage:
#   class AbcWorksheetsController < ApplicationController
#     include Exportable
#     exportable :abc_worksheet
#   end
#
# Configuration is centralized in ExportConfig module.
#
module Exportable
  extend ActiveSupport::Concern

  class_methods do
    # Configures export and share actions for a controller
    #
    # @param resource_key [Symbol] Key matching ExportConfig::RESOURCES (e.g., :abc_worksheet)
    def exportable(resource_key)
      class_attribute :export_resource_key, instance_writer: false
      self.export_resource_key = resource_key
    end
  end

  # GET /resource/:id/export
  # Generates and returns PDF. Use ?print=true for inline display (print preview).
  def export
    resource = current_resource
    pdf_content = ExportConfig.exporter_for(export_resource_key).new(resource).generate
    filename = ExportConfig.filename_for(resource, export_resource_key)
    disposition = params[:print] == 'true' ? 'inline' : 'attachment'

    send_data pdf_content,
              filename: filename,
              type: 'application/pdf',
              disposition: disposition
  rescue StandardError => e
    Rails.logger.error "=== PDF generation failed: #{e.class} - #{e.message} ==="
    Rails.logger.error e.backtrace.first(5).join("\n")

    render json: { error: 'Could not generate PDF. Please try again.' }, status: :internal_server_error
  end

  # POST /resource/:id/share
  # Sends PDF via email to specified recipient
  def share
    resource = current_resource
    recipient_email = parse_recipient_email

    return unless recipient_email

    Rails.logger.info "=== Sending #{export_resource_key} #{resource.id} to #{recipient_email} ==="

    ExportMailer
      .send(export_resource_key, resource, recipient_email)
      .deliver_later

    Rails.logger.info '=== Email queued for delivery ==='

    render json: { message: 'Email sent successfully!' }, status: :ok
  rescue StandardError => e
    handle_share_error(e)
  end

  private

  def current_resource
    instance_variable_get("@#{export_resource_key}")
  end

  def parse_recipient_email
    body = request.raw_post
    email_params = body.present? ? JSON.parse(body) : {}
    recipient_email = email_params['email']

    if recipient_email.blank?
      render_share_error('Email address is required')
      return nil
    end

    unless recipient_email.match?(URI::MailTo::EMAIL_REGEXP)
      render_share_error('Invalid email address format')
      return nil
    end

    recipient_email
  rescue JSON::ParserError
    render_share_error('Invalid request format', :bad_request)
    nil
  end

  def render_share_error(message, status = :unprocessable_content)
    render json: { error: message }, status: status
  end

  def handle_share_error(error)
    Rails.logger.error "=== Email delivery failed: #{error.class} - #{error.message} ==="
    Rails.logger.error error.backtrace.join("\n")

    render json: { error: 'Failed to send email. Please try again.' }, status: :unprocessable_content
  end
end
