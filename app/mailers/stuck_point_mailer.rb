# frozen_string_literal: true

# =============================================================================
# StuckPointMailer - Sends stuck point PDFs via email
# =============================================================================
class StuckPointMailer < ApplicationMailer
  # Sends a stuck point PDF to the user
  def send_stuck_point(user, stuck_point)
    @user = user
    @stuck_point = stuck_point
    @index_event = stuck_point.index_event

    # Generate PDF
    pdf_content = StuckPointPdfGenerator.new(stuck_point).generate

    # Attach PDF
    attachments["#{@index_event.title.parameterize}-stuck-point-#{Date.current}.pdf"] = pdf_content

    mail(
      to: user.email,
      subject: "Your CPT Stuck Point: #{@stuck_point.statement.truncate(50)}"
    )
  end
end
