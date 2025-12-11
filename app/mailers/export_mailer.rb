# frozen_string_literal: true

# =============================================================================
# ExportMailer - Unified email delivery for all PDF exports
# =============================================================================
#
# Sends PDF exports to specified recipients via email. Configuration is
# centralized in ExportConfig module.
#
class ExportMailer < ApplicationMailer
  default from: 'CPT with Ross <support@cptwithross.com>'

  def abc_worksheet(worksheet, recipient_email)
    send_export(:abc_worksheet, worksheet, recipient_email)
  end

  def alternative_thought(worksheet, recipient_email)
    send_export(:alternative_thought, worksheet, recipient_email)
  end

  def stuck_point(stuck_point, recipient_email)
    @index_event = stuck_point.index_event
    send_export(:stuck_point, stuck_point, recipient_email)
  end

  def baseline(baseline, recipient_email)
    @index_event = baseline.index_event
    send_export(:baseline, baseline, recipient_email)
  end

  private

  def send_export(type, resource, recipient_email, template: nil)
    @resource = resource
    @resource_type = resource.class::RESOURCE_TYPE

    attachments[ExportConfig.filename_for(resource, type)] =
      ExportConfig.exporter_for(type).new(resource).generate

    options = { to: recipient_email, subject: ExportConfig.subject_for(resource, type) }
    options[:template_name] = template if template

    mail(options)
  end
end
