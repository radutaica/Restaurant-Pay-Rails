require 'prawn'
require 'prawn/table'

class ReceiptPdfService
  def initialize(contribution)
    @contribution = contribution
    @bill = contribution.bill
    @venue = @bill.venue
    @table = @bill.table
  end

  def generate
    pdf = Prawn::Document.new(
      page_size: 'A4',
      margin: [40, 40, 40, 40]
    )

    # Header
    pdf.text @venue.name, size: 24, style: :bold, align: :center
    pdf.move_down 5
    
    if @venue.address.present?
      pdf.text @venue.address, size: 10, align: :center, color: '666666'
      pdf.move_down 10
    end

    pdf.stroke_horizontal_rule
    pdf.move_down 15

    # Receipt info
    pdf.text "RECEIPT", size: 16, style: :bold
    pdf.move_down 10

    data = [
      ["Date:", @contribution.captured_at&.strftime('%B %d, %Y at %I:%M %p') || Time.current.strftime('%B %d, %Y at %I:%M %p')],
      ["Table:", @table.name],
      ["Receipt #:", "##{@contribution.id}"]
    ]

    pdf.table(data, column_widths: [100, 200]) do
      columns(0).font_style = :bold
      columns(0).width = 100
    end

    pdf.move_down 20

    # Bill items
    pdf.text "Items Ordered", size: 14, style: :bold
    pdf.move_down 10

    items_data = [["Item", "Qty", "Unit Price", "Subtotal"]]
    
    @bill.bill_line_items.each do |line_item|
      items_data << [
        line_item.name,
        line_item.qty.to_s,
        format_money(line_item.unit_price_cents, @bill.currency),
        format_money(line_item.subtotal_cents, @bill.currency)
      ]
    end

    pdf.table(items_data, header: true) do
      row(0).font_style = :bold
      row(0).background_color = 'E8E8E8'
      columns(1..3).align = :right
    end

    pdf.move_down 20

    # Bill totals
    pdf.text "Bill Summary", size: 14, style: :bold
    pdf.move_down 10

    bill_totals = [
      ["Subtotal:", format_money(@bill.subtotal_cents, @bill.currency)],
      ["Tax:", format_money(@bill.tax_cents, @bill.currency)],
      ["Service Fee:", format_money(@bill.fees_cents, @bill.currency)],
      ["Bill Total:", format_money(@bill.total_cents, @bill.currency)]
    ]

    pdf.table(bill_totals, column_widths: [150, 150]) do
      columns(0).font_style = :bold
      columns(1).align = :right
      row(-1).font_style = :bold
      row(-1).font_size = 12
    end

    pdf.move_down 20

    # Contribution details
    pdf.text "Your Payment", size: 14, style: :bold
    pdf.move_down 10

    contribution_data = [
      ["Amount Paid:", format_money(@contribution.allocated_amount_cents, @bill.currency)],
      ["Tip:", format_money(@contribution.tip_cents, @bill.currency)],
      ["Total Charged:", format_money(@contribution.total_charge_cents, @bill.currency)]
    ]

    pdf.table(contribution_data, column_widths: [150, 150]) do
      columns(0).font_style = :bold
      columns(1).align = :right
      row(-1).font_style = :bold
      row(-1).font_size = 14
      row(-1).text_color = '0066CC'
    end

    # Payment status
    if @bill.remaining_cents > 0
      pdf.move_down 15
      pdf.text "Remaining Balance: #{format_money(@bill.remaining_cents, @bill.currency)}", 
               size: 12, 
               style: :italic,
               color: '666666'
    else
      pdf.move_down 15
      pdf.text "✓ Bill Fully Paid", 
               size: 12, 
               style: :bold,
               color: '00AA00'
    end

    pdf.move_down 30

    # Footer
    pdf.stroke_horizontal_rule
    pdf.move_down 10
    pdf.text "Thank you for your visit!", size: 10, align: :center, color: '666666'
    pdf.text "Payment processed via Stripe", size: 8, align: :center, color: '999999'

    pdf.render
  end

  private

  def format_money(cents, currency = 'ron')
    amount = cents / 100.0
    case currency.downcase
    when 'ron', 'lei'
      "#{format('%.2f', amount)} RON"
    when 'usd', 'dollar'
      "$#{format('%.2f', amount)}"
    when 'eur', 'euro'
      "€#{format('%.2f', amount)}"
    else
      "#{format('%.2f', amount)} #{currency.upcase}"
    end
  end
end

