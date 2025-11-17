require 'prawn'
require 'prawn/table'

class ReceiptPdfService
  PRIMARY_TEXT = '111827'.freeze
  SECONDARY_TEXT = '6B7280'.freeze
  MUTED_TEXT = '9CA3AF'.freeze
  BORDER_COLOR = 'E5E7EB'.freeze

  def initialize(contribution)
    @contribution = contribution
    @bill = contribution.bill
    @venue = @bill.venue
    @table = @bill.table
  end

  def generate
    pdf = Prawn::Document.new(
      page_size: 'A4',
      margin: [36, 48, 48, 48]
    )

    configure_fonts(pdf)

    draw_header(pdf)
    draw_divider(pdf)
    draw_payment_identifiers(pdf)
    draw_divider(pdf)
    draw_bill_summary(pdf)
    draw_divider(pdf)
    draw_payment_section(pdf)
    draw_divider(pdf)
    draw_status_section(pdf)
    pdf.move_down 10
    draw_details_button(pdf)
    pdf.move_down 20
    draw_footer(pdf)

    pdf.render
  end

  private

  def configure_fonts(pdf)
    font_loaded = false

    [
      {
        family: 'Arial',
        paths: {
            normal: '/System/Library/Fonts/Supplemental/Arial.ttf',
            bold: '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
            italic: '/System/Library/Fonts/Supplemental/Arial Italic.ttf',
            bold_italic: '/System/Library/Fonts/Supplemental/Arial Bold Italic.ttf'
          }
      },
      {
        family: 'ArialUnicode',
        paths: {
            normal: '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
            bold: '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
            italic: '/System/Library/Fonts/Supplemental/Arial Italic.ttf',
            bold_italic: '/System/Library/Fonts/Supplemental/Arial Bold Italic.ttf'
          }
      },
      {
        family: 'DejaVu',
        paths: {
            normal: '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
            bold: '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
            italic: '/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf',
            bold_italic: '/usr/share/fonts/truetype/dejavu/DejaVuSans-BoldOblique.ttf'
          }
      },
      {
        family: 'ArialWin',
        paths: {
            normal: 'C:/Windows/Fonts/arial.ttf',
            bold: 'C:/Windows/Fonts/arialbd.ttf',
            italic: 'C:/Windows/Fonts/ariali.ttf',
            bold_italic: 'C:/Windows/Fonts/arialbi.ttf'
          }
      }
    ].each do |font|
      next unless File.exist?(font[:paths][:normal])

      pdf.font_families.update(font[:family] => font[:paths])
      pdf.font font[:family]
      font_loaded = true
      break
    end

    return if font_loaded

    pdf.font 'Helvetica'
    rescue => e
      Rails.logger.warn "Could not load UTF-8 font: #{e.message}. Using default font."
    pdf.font 'Helvetica'
    end

  def draw_header(pdf)
    pdf.fill_color PRIMARY_TEXT
    pdf.text @venue.name, size: 24, style: :bold, align: :center
    pdf.move_down 4
    pdf.fill_color SECONDARY_TEXT
    pdf.text "Masa #{@table.name}", size: 11, align: :center
    pdf.move_down 2
    pdf.fill_color MUTED_TEXT
    pdf.text formatted_receipt_datetime, size: 9, align: :center
    pdf.move_down 20
  end

  def draw_divider(pdf)
    pdf.move_down 14
    pdf.stroke_color BORDER_COLOR
    pdf.stroke_horizontal_rule
    pdf.move_down 14
  end

  def draw_payment_identifiers(pdf)
    data = [
      ['ID plată:', formatted_payment_reference],
      ['Stripe ID:', stripe_reference]
    ]

    pdf.table(
      data,
      column_widths: [120, pdf.bounds.width - 120],
      cell_style: {
        borders: [:bottom],
        border_width: 0.5,
        border_color: BORDER_COLOR,
        padding: [8, 0, 8, 0],
        size: 10
      }
    ) do
      columns(0).font_style = :bold
      columns(0).text_color = SECONDARY_TEXT
      columns(1).text_color = PRIMARY_TEXT
    end
  end

  def draw_section_divider(pdf)
    pdf.move_down 18
    pdf.stroke_color BORDER_COLOR
    pdf.stroke_horizontal_rule
    pdf.move_down 18
  end

  def draw_bill_summary(pdf)
    section_title(pdf, 'REZUMAT NOTĂ DE PLATĂ')

    summary_data = [
      ['Total consumat:', format_money(@bill.total_cents, @bill.currency)],
      ['Plătit înainte:', format_money(paid_before_cents, @bill.currency)]
    ]

    draw_key_value_table(pdf, summary_data)
    pdf.move_down 10
  end

  def draw_payment_section(pdf)
    section_title(pdf, 'PLATA TA', size: 12)
    draw_callout(pdf, share_callout_text) if share_callout_text

    payment_data = [
      ['Suma plătită:', format_money(@contribution.allocated_amount_cents, @bill.currency)],
      ['Bacșiș inclus:', signed_money(@contribution.tip_cents)],
      ['Metodă de plată:', payment_method_display]
    ]

    draw_key_value_table(pdf, payment_data, highlight_row: 0)
    pdf.move_down 10
  end

  def draw_status_section(pdf)
    section_title(pdf, 'STATUS NOTĂ')

    status = status_props
    draw_status_badge(pdf, status[:text], status[:background], status[:text_color])

    pdf.move_down 8
  end

  def draw_details_button(pdf)
    button_height = 36
    left = pdf.bounds.left
    top = pdf.cursor
    width = pdf.bounds.width

    pdf.fill_color 'F3F4F6'
    pdf.fill_rounded_rectangle [left, top], width, button_height, 8
    pdf.fill_color PRIMARY_TEXT
    pdf.text_box 'Vezi detalii complete ->',
                 at: [left, top - 10],
                 width: width,
                 height: button_height,
                 align: :center,
                 size: 10,
                 style: :bold,
                 valign: :center
    pdf.move_down button_height + 12
  end

  def draw_footer(pdf)
    pdf.fill_color SECONDARY_TEXT
    pdf.text "Vă mulțumim că ne-ați ales!", size: 9, align: :center
    pdf.move_down 4
    pdf.fill_color MUTED_TEXT
    pdf.text contact_email, size: 8, align: :center
    pdf.text 'Plata procesată prin Stripe', size: 7, align: :center
  end

  def section_title(pdf, title, size: 11)
    pdf.fill_color SECONDARY_TEXT
    pdf.text title, size: size, style: :bold
    pdf.move_down 10
  end

  def draw_key_value_table(pdf, rows, highlight_row: nil)
    pdf.table(
      rows,
      width: pdf.bounds.width,
      cell_style: {
        borders: [:bottom],
        border_color: BORDER_COLOR,
        border_width: 0.4,
        padding: [8, 0, 8, 0],
        size: 11
      }
    ) do
      columns(0).font_style = :bold
      columns(0).text_color = SECONDARY_TEXT
      columns(1).text_color = PRIMARY_TEXT

      Array(highlight_row).compact.each do |row_index|
        row(row_index).font_style = :bold
        row(row_index).size = 12
      end
    end
  end

  def draw_callout(pdf, text)
    box_height = 40
    left = pdf.bounds.left
    top = pdf.cursor
    width = pdf.bounds.width

    pdf.fill_color 'E3ECFF'
    pdf.fill_rounded_rectangle [left, top], width, box_height, 12
    pdf.fill_color '1D4ED8'
    pdf.text_box text,
                 at: [left + 12, top - 14],
                 width: width - 24,
                 height: box_height - 12,
                 size: 10,
                 style: :bold,
                 valign: :center
    pdf.move_down box_height + 10
  end

  def draw_status_badge(pdf, text, background, text_color)
    badge_height = 36
    left = pdf.bounds.left
    top = pdf.cursor
    width = pdf.bounds.width

    pdf.fill_color background
    pdf.fill_rounded_rectangle [left, top], width, badge_height, 12
    pdf.fill_color text_color
    pdf.text_box text,
                 at: [left + 12, top - 12],
                 width: width - 24,
                 height: badge_height - 10,
                 size: 10,
                 style: :bold,
                 valign: :center
    pdf.move_down badge_height + 6
  end

  def formatted_receipt_datetime
    receipt_time = (@contribution.captured_at || @contribution.updated_at || Time.current)
    receipt_time.in_time_zone(Time.zone).strftime('%d %b %Y, %H:%M')
  end

  def formatted_payment_reference
    base = @contribution.id.to_s.rjust(6, '0')
    "TRX–#{receipt_time_year}–#{base}"
  end

  def receipt_time_year
    (@contribution.captured_at || Time.current).year
  end

  def stripe_reference
    @contribution.stripe_payment_intent_id.presence || '—'
  end

  def paid_before_cents
    @paid_before_cents ||= @bill.contributions
                                .where(status: 'succeeded')
                                .where('created_at < ?', (@contribution.created_at || Time.current))
                                .sum(:total_charge_cents)
  end

  def share_callout_text
    return if @bill.total_cents.to_i.zero?

    percent = ((@contribution.total_charge_cents.to_f / @bill.total_cents) * 100).round
    return if percent.zero?

    if percent >= 100
      'Ai achitat întreaga notă.'
    else
      "Ai achitat ~#{percent}% din nota totală."
    end
  end

  def signed_money(cents)
    return format_money(cents, @bill.currency) if cents <= 0

    "+#{format_money(cents, @bill.currency)}"
  end

  def payment_method_display
    return 'Card' if @contribution.payment_method.blank?

    @contribution.payment_method.split('_').map(&:capitalize).join(' ')
  end

  def status_props
    if %w[failed canceled expired].include?(@contribution.status)
      {
        text: 'Plata a eșuat. Încercați din nou.',
        background: 'FEE2E2',
        text_color: 'B91C1C'
      }
    elsif @bill.remaining_cents.to_i > 0
      {
        text: "Mai sunt de plată #{format_money(@bill.remaining_cents, @bill.currency)}.",
        background: 'FEF3C7',
        text_color: '92400E'
      }
    else
      {
        text: 'Nota este complet achitată.',
        background: 'D1FAE5',
        text_color: '065F46'
      }
    end
  end

  def contact_email
    return @venue.contact_email if @venue.respond_to?(:contact_email) && @venue.contact_email.present?

    "contact@#{@venue.slug}.ro"
  end

  def format_money(cents, currency = 'ron')
    amount = cents.to_i / 100.0
    case currency.to_s.downcase
    when 'ron', 'lei'
      "#{format('%.2f', amount)} RON"
    when 'usd', 'dollar'
      "$#{format('%.2f', amount)}"
    when 'eur', 'euro'
      "€#{format('%.2f', amount)}"
    else
      "#{format('%.2f', amount)} #{currency.to_s.upcase}"
    end
  end
end

