# frozen_string_literal: true

# =============================================================================
# WorksheetPdfGenerator - Service for generating PDF exports of CPT worksheets
# =============================================================================
#
# Generates formatted PDF documents for ABC Worksheets and Alternative Thoughts
# using Prawn and Prawn-Table gems with professional styling matching the app design.
#
class WorksheetPdfGenerator
  # App color scheme
  COLORS = {
    primary: '0D6EFD',    # Blue
    secondary: '6C757D',  # Gray
    light: 'F8F9FA',      # Light gray
    dark: '212529',       # Dark
    border: 'DEE2E6'      # Border gray
  }.freeze

  def initialize(worksheet)
    @worksheet = worksheet
    @stuck_point = worksheet.stuck_point
    @index_event = @stuck_point.index_event
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
        add_context_header(pdf)
        add_content(pdf)
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

  # Adds context header with Index Event and Stuck Point
  def add_context_header(pdf)
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

    # Stuck Point box
    pdf.fill_color COLORS[:light]
    pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 40
    pdf.fill_color COLORS[:dark]

    pdf.bounding_box([10, pdf.cursor - 10], width: pdf.bounds.width - 20) do
      pdf.text 'Stuck Point', size: 10, color: COLORS[:secondary], style: :bold
      pdf.move_down 3
      pdf.text @stuck_point.statement, size: 12
    end

    pdf.move_down 50
  end

  # Routes to appropriate content generator based on worksheet type
  def add_content(pdf)
    case @worksheet
    when AbcWorksheet
      add_abc_worksheet_content(pdf)
    when AlternativeThought
      add_alternative_thought_content(pdf)
    end
  end

  # Generates content for ABC Worksheet matching the 3-column card layout
  def add_abc_worksheet_content(pdf)
    # Card header
    add_card_header(pdf, 'ABC Worksheet')

    # Column headers
    header_data = [
      [
        { content: "A\nActivating Event\nSomething happens", align: :center, background_color: COLORS[:light] },
        { content: "B\nBelief/Stuck Point\nI tell myself something", align: :center, background_color: COLORS[:light] },
        { content: "C\nConsequence\nI feel something", align: :center, background_color: COLORS[:light] }
      ]
    ]

    # Content data
    activating = @worksheet.activating_event.present? ? @worksheet.activating_event : 'Not yet written.'
    beliefs = @worksheet.beliefs.present? ? @worksheet.beliefs : 'Not yet written.'

    # Format emotions for display
    emotions_text = if @worksheet.emotions.present? && @worksheet.emotions.any?
                      @worksheet.emotions.sort_by { |e| -e['intensity'] }
                                .map { |e| "#{e['emotion'].capitalize}: #{e['intensity']}/10" }
                                .join("\n")
                    else
                      'No emotions recorded.'
                    end

    content_data = [[activating, beliefs, emotions_text]]

    # Create table with automatic width distribution
    # Note: Not setting explicit width - let Prawn calculate based on content and columns
    pdf.table(header_data + content_data,
              column_widths: [pdf.bounds.width / 3.0] * 3,
              cell_style: {
                padding: 10,
                borders: [:left, :right, :top, :bottom],
                border_color: COLORS[:border]
              }) do
      row(0).font_style = :bold
      row(0).size = 9
      row(0).text_color = COLORS[:secondary]
      row(1).size = 10
    end

    pdf.move_down 20
    add_timestamp(pdf, @worksheet.updated_at)
  end

  # Generates content for Alternative Thought worksheet with card-based sections
  def add_alternative_thought_content(pdf)
    pdf.text @worksheet.title, size: 18, style: :bold, color: COLORS[:dark]
    pdf.move_down 15

    # Exploring Thoughts Card
    if @worksheet.exploring_complete?
      add_card_header(pdf, 'Exploring Thoughts')
      AlternativeThought::EXPLORING_QUESTIONS.each do |field, question|
        answer = @worksheet.send(field)
        next if answer.blank?

        pdf.text question, size: 11, style: :bold, color: COLORS[:dark]
        pdf.move_down 3
        pdf.text answer, size: 10
        pdf.move_down 10
      end
      pdf.move_down 10
    end

    # Thinking Patterns Card
    if @worksheet.patterns_complete?
      add_card_header(pdf, 'Thinking Patterns')
      AlternativeThought::THINKING_PATTERNS.each do |field, pattern|
        answer = @worksheet.send(field)
        next if answer.blank?

        pdf.text pattern, size: 11, style: :bold, color: COLORS[:dark]
        pdf.move_down 3
        pdf.text answer, size: 10
        pdf.move_down 10
      end
      pdf.move_down 10
    end

    # Alternative Thought Card
    if @worksheet.alternative_thought.present?
      add_card_header(pdf, 'Alternative Thought(s)')
      pdf.text @worksheet.alternative_thought, size: 10
      pdf.move_down 10

      if @worksheet.alternative_thought_belief.present?
        pdf.text "Belief rating: #{@worksheet.alternative_thought_belief}%",
                 size: 10, style: :bold, color: COLORS[:primary]
      end
      pdf.move_down 15
    end

    # Re-rate Old Stuck Point Card
    if @worksheet.stuck_point_belief_after.present?
      add_card_header(pdf, 'Re-Rate Old Stuck Point')
      pdf.text "Current belief in stuck point: #{@worksheet.stuck_point_belief_after}%",
               size: 10, style: :bold, color: COLORS[:primary]
      pdf.move_down 15
    end

    # Emotions After Card
    if @worksheet.emotions_after.present? && @worksheet.emotions_after.any?
      add_card_header(pdf, 'Emotion(s)')
      pdf.text 'How you feel now after completing the worksheet:', size: 9, color: COLORS[:secondary]
      pdf.move_down 8

      emotions_text = @worksheet.emotions_after
                                .select { |e| e['intensity'].to_i.positive? }
                                .sort_by { |e| -e['intensity'].to_i }
                                .map { |e| "#{e['emotion'].capitalize}: #{e['intensity']}/10" }
                                .join("\n")

      pdf.text emotions_text, size: 10
      pdf.move_down 15
    end

    add_timestamp(pdf, @worksheet.updated_at)
  end

  # Helper: Adds a card header with background color and border (matching Bootstrap card-header)
  # Automatically starts a new page if there's not enough space for the section
  def add_card_header(pdf, title)
    # Check if there's enough space for a section header + some content (at least 100 points)
    # If not, start a new page to avoid orphaned section headers
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

  # Helper: Adds timestamp footer
  def add_timestamp(pdf, updated_at)
    pdf.fill_color COLORS[:secondary]
    pdf.text "Last updated: #{updated_at.strftime('%B %d, %Y at %l:%M %p')}", size: 8, align: :right
    pdf.fill_color COLORS[:dark]
  end
end
