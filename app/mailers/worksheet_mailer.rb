# frozen_string_literal: true

# =============================================================================
# WorksheetMailer - Email delivery for worksheet PDFs
# =============================================================================
#
# Sends worksheet PDFs to users via email with appropriate attachments
#
class WorksheetMailer < ApplicationMailer
  # Sends a worksheet PDF to the user's email
  #
  # @param user [User] The recipient user
  # @param worksheet [AbcWorksheet, AlternativeThought] The worksheet to send
  def send_worksheet(user, worksheet)
    @user = user
    @worksheet = worksheet
    @worksheet_type = worksheet.class.name.titleize

    # Generate PDF
    pdf_content = WorksheetPdfGenerator.new(worksheet).generate

    # Attach PDF
    attachments["#{worksheet.title.parameterize}-#{Date.current}.pdf"] = pdf_content

    mail(
      to: user.email,
      subject: "Your CPT Worksheet: #{worksheet.title}"
    )
  end
end
