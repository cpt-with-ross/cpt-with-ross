# frozen_string_literal: true

module PdfExporters
  # =============================================================================
  # PdfExporters::Base - Base class for PDF generation services
  # =============================================================================
  #
  # Provides shared functionality for generating styled PDF documents including:
  # - Professional gray banner headers matching official CPT worksheets
  # - Header with logo and app branding
  # - Footer with page numbers and generation date
  # - ABC worksheet table rendering
  # - Alternating row tables for checklists
  #
  # Subclasses should implement #add_content(pdf) to add their specific content.
  #
  class Base
    # Professional worksheet color scheme
    COLORS = {
      banner_gray: 'CCCCCC',    # Gray banner background
      text_dark: '333333',      # Main text
      text_light: '666666',     # Secondary/muted text
      border: 'AAAAAA',         # Table borders
      row_alt: 'F5F5F5',        # Alternating row background
      row_white: 'FFFFFF'       # Normal row background
    }.freeze

    # Page break thresholds (pixels from bottom)
    PAGE_BREAK_SECTION_THRESHOLD = 200  # For new sections
    PAGE_BREAK_ITEM_THRESHOLD = 150     # For items in loops

    # Empty state messages for consistent display across exporters
    EMPTY_STATE_MESSAGES = {
      abc_worksheets: 'No ABC worksheets have been created yet.',
      alternative_thoughts: 'No alternative thoughts have been created yet.',
      stuck_points: 'No stuck points have been identified yet.',
      emotions: 'No emotions recorded.',
      not_written: 'Not yet written.'
    }.freeze

    PAGE_SIZE = 'LETTER'
    MARGIN_TOP = 100    # Space for header
    MARGIN_BOTTOM = 50  # Space for footer
    MARGIN_SIDES = 50

    def initialize
      @logo_path = Rails.public_path.join('logo.png')
    end

    # Generates and returns PDF document as a string
    def generate
      Prawn::Document.new(
        page_size: PAGE_SIZE,
        margin: [MARGIN_TOP, MARGIN_SIDES, MARGIN_BOTTOM, MARGIN_SIDES]
      ) do |pdf|
        pdf.repeat(:all) do
          add_page_header(pdf)
          add_page_footer(pdf)
        end

        # Ensure cursor starts at top of content area
        pdf.move_cursor_to pdf.bounds.top
        add_content(pdf)

        # Add dynamic page numbers
        add_page_numbers(pdf)
      end.render
    end

    protected

    # Override in subclasses to add specific content
    def add_content(pdf)
      raise NotImplementedError, "#{self.class} must implement #add_content"
    end

    # Adds header with logo and app title on every page (draws in margin area)
    def add_page_header(pdf)
      pdf.canvas do
        pdf.bounding_box([MARGIN_SIDES, pdf.bounds.top - 20], width: pdf.bounds.width - (MARGIN_SIDES * 2),
                                                              height: 70) do
          pdf.image @logo_path, at: [0, 60], width: 40, height: 40 if File.exist?(@logo_path)

          # Text vertically centered with logo (logo spans y=20 to y=60, center ~40)
          pdf.fill_color COLORS[:text_dark]
          pdf.draw_text 'CPT with Ross', at: [50, 42], size: 20, style: :bold

          pdf.fill_color COLORS[:text_light]
          pdf.draw_text 'Cognitive Processing Therapy', at: [50, 25], size: 10

          pdf.fill_color COLORS[:text_dark]
          pdf.stroke_color COLORS[:border]
          pdf.stroke_horizontal_line 0, pdf.bounds.width, at: 0
        end
      end
    end

    # Adds footer line and date on every page (draws in margin area)
    def add_page_footer(pdf)
      pdf.canvas do
        footer_y = 35
        pdf.stroke_color COLORS[:border]
        pdf.stroke_horizontal_line MARGIN_SIDES, pdf.bounds.width - MARGIN_SIDES, at: footer_y

        pdf.fill_color COLORS[:text_light]
        pdf.draw_text "Printed: #{Date.current.strftime('%B %d, %Y')}", at: [MARGIN_SIDES, footer_y - 15], size: 8
        pdf.fill_color COLORS[:text_dark]
      end
    end

    # Adds dynamic page numbers to all pages (called after content is complete)
    def add_page_numbers(pdf)
      pdf.number_pages 'Page <page>',
                       at: [pdf.bounds.right - 40, -30],
                       size: 8,
                       color: COLORS[:text_light]
    end

    # Formats emotions array for display
    def format_emotions(emotions)
      return EMPTY_STATE_MESSAGES[:emotions] if emotions.blank?

      emotions.sort_by { |e| -e['intensity'].to_i }
              .map { |e| "#{e['emotion'].capitalize}: #{e['intensity']}/10" }
              .join("\n")
    end

    # Adds context header with Index Event and Stuck Point boxes
    def add_worksheet_context(pdf, index_event:, stuck_point:)
      add_section_card(pdf, title: 'Index Event', content: index_event.title)
      add_section_card(pdf, title: 'Stuck Point', content: stuck_point.statement)
    end

    # Adds a section card with title and content
    def add_section_card(pdf, title:, content:, inline_format: false)
      ensure_space_for_section(pdf)

      pdf.fill_color COLORS[:row_alt]
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 25
      pdf.fill_color COLORS[:text_dark]

      pdf.move_down 7
      pdf.indent(10) do
        pdf.text title, size: 11, style: :bold
      end
      pdf.move_down 8
      pdf.indent(10) do
        pdf.text content.presence || 'Not specified', size: 10, inline_format: inline_format
      end
      pdf.move_down 8
    end

    # Adds a section card header only (no content area)
    def add_section_card_header(pdf, title, dark: false)
      ensure_space_for_section(pdf)

      pdf.fill_color dark ? COLORS[:banner_gray] : COLORS[:row_alt]
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 25
      pdf.fill_color COLORS[:text_dark]

      pdf.move_down 7
      pdf.indent(10) do
        pdf.text title, size: 11, style: :bold
      end
      pdf.move_down 8
    end

    # Starts a new page if cursor is below the section threshold (200px)
    # Use before adding new sections or card headers
    def ensure_space_for_section(pdf)
      pdf.start_new_page if pdf.cursor < PAGE_BREAK_SECTION_THRESHOLD
    end

    # Starts a new page if cursor is below the item threshold (150px)
    # Use before adding items within loops
    def ensure_space_for_item(pdf)
      pdf.start_new_page if pdf.cursor < PAGE_BREAK_ITEM_THRESHOLD
    end

    # Conditional page break - only if not first item
    # Use in loops where first item shouldn't trigger a page break
    def ensure_space_for_section_unless_first(pdf, index)
      pdf.start_new_page if pdf.cursor < PAGE_BREAK_SECTION_THRESHOLD && index.positive?
    end

    # Renders an empty state message with consistent styling
    def render_empty_state(pdf, message:, move_down: 20)
      pdf.text message, size: 10, color: COLORS[:text_light], style: :italic
      pdf.move_down move_down if move_down.positive?
    end

    # =========================================================================
    # Professional worksheet styling helpers
    # =========================================================================

    # Adds a gray banner header matching professional CPT worksheet style
    def add_banner_header(pdf, title)
      pdf.fill_color COLORS[:banner_gray]
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 30
      pdf.fill_color COLORS[:text_dark]

      pdf.move_down 10
      pdf.text title, size: 16, style: :bold, align: :center
      pdf.move_down 10
    end

    # Renders a professional ABC worksheet table (3-column format)
    def add_professional_abc_table(pdf, abc_worksheet, show_title: false)
      if show_title
        pdf.text abc_worksheet.title, size: 12, style: :bold, color: COLORS[:text_dark]
        pdf.move_down 10
      end

      col_width = pdf.bounds.width / 3.0

      header_data = [
        [
          { content: "A\nActivating event\n\"Something happens\"", align: :center },
          { content: "B\nBelief/stuck point\n\"I tell myself something\"", align: :center },
          { content: "C\nConsequence\n\"I feel something\"", align: :center }
        ]
      ]

      activating = abc_worksheet.activating_event.presence || 'Not yet written.'
      beliefs = abc_worksheet.beliefs.presence || 'Not yet written.'
      emotions_text = format_emotions(abc_worksheet.emotions)

      content_data = [[activating, beliefs, emotions_text]]

      pdf.table(header_data + content_data,
                column_widths: [col_width] * 3,
                cell_style: {
                  padding: 10,
                  borders: %i[left right top bottom],
                  border_color: COLORS[:border],
                  border_width: 0.5
                }) do |table|
        table.row(0).background_color = COLORS[:banner_gray]
        table.row(0).font_style = :bold
        table.row(0).size = 9
        table.row(0).text_color = COLORS[:text_dark]
        table.row(1).size = 10
        table.row(1).valign = :top
      end

      pdf.move_down 15
    end

    # Renders an alternating-row table (for PCL-5 checklist style)
    def add_alternating_table(pdf, headers:, rows:, column_widths: nil)
      data = [headers] + rows

      pdf.table(data,
                column_widths: column_widths,
                header: true,
                row_colors: [COLORS[:row_white], COLORS[:row_alt]],
                cell_style: {
                  padding: [6, 8],
                  borders: %i[top bottom],
                  border_color: COLORS[:border],
                  border_width: 0.5,
                  size: 9
                }) do |table|
        table.row(0).background_color = COLORS[:banner_gray]
        table.row(0).font_style = :bold
        table.row(0).borders = %i[top bottom]
        # Center the rating columns (columns 1-5) horizontally and vertically
        table.columns(1..-1).align = :center
        table.columns(1..-1).valign = :center
      end
    end

    # Renders a labeled field (label + value)
    def add_labeled_field(pdf, label:, value:, inline: false)
      if inline
        pdf.text "<b>#{label}:</b> #{value || 'Not specified'}",
                 size: 10, inline_format: true, color: COLORS[:text_dark]
      else
        pdf.text label, size: 10, style: :bold, color: COLORS[:text_dark]
        pdf.move_down 3
        pdf.text value.presence || 'Not specified', size: 10, color: COLORS[:text_dark]
      end
      pdf.move_down 5
    end

    # Renders a checkbox-style item
    def add_checkbox_item(pdf, text, checked: false)
      checkbox = checked ? '[X]' : '[ ]'
      pdf.text "#{checkbox} #{text}", size: 10, color: COLORS[:text_dark]
      pdf.move_down 5
    end
  end
end
