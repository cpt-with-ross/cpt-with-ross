# frozen_string_literal: true

# =============================================================================
# SummaryMailer - Sends index event summary PDFs via email
# =============================================================================
class SummaryMailer < ApplicationMailer
  # Sends an index event summary PDF to the user
  def send_summary(user, index_event)
    @user = user
    @index_event = index_event

    # Generate PDF
    pdf_content = SummaryPdfGenerator.new(index_event).generate

    # Attach PDF
    attachments["#{@index_event.title.parameterize}-summary-#{Date.current}.pdf"] = pdf_content

    mail(
      to: user.email,
      subject: "Your CPT Summary: #{@index_event.title}"
    )
  end
end
