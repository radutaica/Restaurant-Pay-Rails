class ContributionReceiptMailer < ApplicationMailer
  def receipt_email(contribution)
    @contribution = contribution
    @bill = contribution.bill
    @venue = @bill.venue
    @table = @bill.table

    # Generate PDF
    pdf_service = ReceiptPdfService.new(contribution)
    pdf_data = pdf_service.generate

    # Attach PDF
    attachments["receipt_#{contribution.id}.pdf"] = {
      mime_type: 'application/pdf',
      content: pdf_data
    }

    mail(
      to: contribution.email,
      subject: "Receipt from #{@venue.name} - Table #{@table.name}"
    )
  end
end

