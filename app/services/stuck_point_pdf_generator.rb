# frozen_string_literal: true

# =============================================================================
# StuckPointPdfGenerator - Service for generating PDF of a stuck point
# =============================================================================
#
# Generates a PDF document containing:
# - Index Event title
# - Stuck Point statement
# - List of ABC Worksheets associated with the stuck point
# - List of Alternative Thoughts associated with the stuck point
# (Does NOT include the full content of worksheets)
#
class StuckPointPdfGenerator
  # App color scheme (matching WorksheetPdfGenerator)
  COLORS = {
    primary: '0D6EFD',    # Blue
    secondary: '6C757D',  # Gray
    light: 'F8F9FA',      # Light gray
    dark: '212529',       # Dark
    border: 'DEE2E6'      # Border gray
  }.freeze

  def initialize(stuck_point)
    @stuck_point = stuck_point
    @index_event = stuck_point.index_event
    @abc_worksheets = stuck_point.abc_worksheets.order(created_at: :asc)
    @alternative_thoughts = stuck_point.alternative_thoughts.order(created_at: :asc)
    @logo_path = Rails.root.join('app/assets/images/logo.png')
  end

  # Generates and returns PDF document as a string
  def generate
    Prawn::Document.new(page_size: 'LETTER', margin: 50) do |pdf|
      # Set up repeating header and footer on all pages
      pdf.repeat(:all) do
        add_page_header(pdf)
        add_page_footer(pdf)
      end

      # Main content
      pdf.bounding_box([0, pdf.bounds.top - 80], width: pdf.bounds.width, height: pdf.bounds.height - 140) do
        add_index_event_header(pdf)
        add_stuck_point_section(pdf)
        add_worksheets_list(pdf)
      end
    end.render
  end

  private

  # Adds header with logo and app title on every page
  def add_page_header(pdf)
    pdf.bounding_box([0, pdf.bounds.top], width: pdf.bounds.width, height: 70) do
      if File.exist?(@logo_path)
        # Logo on left
        pdf.image @logo_path, at: [0, 60], width: 40, height: 40
      end

      # App title and subtitle with proper spacing
      pdf.fill_color COLORS[:primary]
      pdf.draw_text 'CPT with Ross', at: [50, 48], size: 20, style: :bold

      pdf.fill_color COLORS[:secondary]
      pdf.draw_text 'Cognitive Processing Therapy', at: [50, 32], size: 10

      pdf.fill_color COLORS[:dark]

      # Horizontal line
      pdf.stroke_color COLORS[:border]
      pdf.stroke_horizontal_line 0, pdf.bounds.width, at: 0
    end
  end

  # Adds footer with page numbers and date
  def add_page_footer(pdf)
    pdf.bounding_box([0, 30], width: pdf.bounds.width, height: 20) do
      # Horizontal line
      pdf.stroke_color COLORS[:border]
      pdf.stroke_horizontal_line 0, pdf.bounds.width, at: 20

      # Footer text
      pdf.fill_color COLORS[:secondary]
      pdf.text_box "Generated: #{Date.current.strftime('%B %d, %Y')}",
                   at: [0, 10],
                   size: 8,
                   align: :left

      pdf.text_box "Page #{pdf.page_number}",
                   at: [0, 10],
                   width: pdf.bounds.width,
                   size: 8,
                   align: :right
      pdf.fill_color COLORS[:dark]
    end
  end

  # Adds index event header section
  def add_index_event_header(pdf)
    # Title
    pdf.text 'Stuck Point Overview', size: 24, style: :bold, color: COLORS[:dark]
    pdf.move_down 20

    # Index Event box
    pdf.fill_color COLORS[:light]
    pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 50
    pdf.fill_color COLORS[:dark]

    pdf.bounding_box([10, pdf.cursor - 10], width: pdf.bounds.width - 20) do
      pdf.text 'Index Event', size: 10, color: COLORS[:secondary], style: :bold
      pdf.move_down 5
      pdf.text @index_event.title, size: 16, style: :bold
    end

    pdf.move_down 60
  end

  # Adds stuck point section
  def add_stuck_point_section(pdf)
    # Stuck Point header
    add_card_header(pdf, "Stuck Point")

    # Stuck Point statement
    pdf.text @stuck_point.statement, size: 12, color: COLORS[:dark]
    pdf.move_down 30
  end

  # Adds list of worksheets
  def add_worksheets_list(pdf)
    # ABC Worksheets section
    add_card_header(pdf, "ABC Worksheets")

    if @abc_worksheets.any?
      @abc_worksheets.each_with_index do |worksheet, idx|
        pdf.text "#{idx + 1}. #{worksheet.title}", size: 11, color: COLORS[:dark]
        pdf.move_down 8
      end
    else
      pdf.text 'No ABC worksheets have been created yet.', size: 10, color: COLORS[:secondary], style: :italic
    end

    pdf.move_down 20

    # Alternative Thoughts section
    add_card_header(pdf, "Alternative Thoughts")

    if @alternative_thoughts.any?
      @alternative_thoughts.each_with_index do |thought, idx|
        pdf.text "#{idx + 1}. #{thought.title}", size: 11, color: COLORS[:dark]
        pdf.move_down 8
      end
    else
      pdf.text 'No alternative thoughts have been created yet.', size: 10, color: COLORS[:secondary], style: :italic
    end
  end

  # Helper: Adds a card header with background color and border
  def add_card_header(pdf, title)
    # Check if there's enough space for a section header
    if pdf.cursor < 150
      pdf.start_new_page
    end

    # Draw background rectangle
    pdf.fill_color COLORS[:secondary]
    pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 30
    pdf.fill_color COLORS[:dark]

    # Add title text
    pdf.bounding_box([10, pdf.cursor - 8], width: pdf.bounds.width - 20) do
      pdf.fill_color 'FFFFFF'
      pdf.text title, size: 13, style: :bold
      pdf.fill_color COLORS[:dark]
    end

    pdf.move_down 35
  end
end
