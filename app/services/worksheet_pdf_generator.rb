# frozen_string_literal: true

# =============================================================================
# WorksheetPdfGenerator - Service for generating PDF exports of CPT worksheets
# =============================================================================
#
# Generates formatted PDF documents for ABC Worksheets and Alternative Thoughts
# using Prawn and Prawn-Table gems.
#
# PDF Structure:
# - Index Event title (large font at top)
# - Stuck Point statement (medium font)
# - Worksheet content formatted appropriately for the type
#
class WorksheetPdfGenerator
  def initialize(worksheet)
    @worksheet = worksheet
    @stuck_point = worksheet.stuck_point
    @index_event = @stuck_point.index_event
  end

  # Generates and returns PDF document as a string
  def generate
    Prawn::Document.new do |pdf|
      add_header(pdf)
      add_content(pdf)
    end.render
  end

  private

  # Adds the header section with Index Event and Stuck Point
  def add_header(pdf)
    # Index Event Title (large)
    pdf.text @index_event.title, size: 24, style: :bold
    pdf.move_down 10

    # Stuck Point (medium)
    pdf.text 'Stuck Point:', size: 14, style: :bold
    pdf.text @stuck_point.statement, size: 12
    pdf.move_down 20
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

  # Generates content for ABC Worksheet
  def add_abc_worksheet_content(pdf)
    pdf.text @worksheet.title, size: 18, style: :bold
    pdf.move_down 15

    # A. Activating Event
    add_section(pdf, 'A. Activating Event', @worksheet.activating_event)

    # B. Beliefs
    add_section(pdf, 'B. Beliefs', @worksheet.beliefs)

    # C. Consequences (legacy text field)
    add_section(pdf, 'C. Consequences', @worksheet.consequences) if @worksheet.consequences.present?

    # C. Emotions (structured JSONB)
    if @worksheet.emotions.present? && @worksheet.emotions.any?
      add_emotions_section(pdf, 'C. Emotions', @worksheet.emotions)
    end
  end

  # Generates content for Alternative Thought worksheet
  def add_alternative_thought_content(pdf)
    pdf.text @worksheet.title, size: 18, style: :bold
    pdf.move_down 15

    # B. Stuck Point Belief (0-100%)
    if @worksheet.stuck_point_belief_before.present?
      pdf.text 'B. How much do you believe the stuck point now? (0-100%)', size: 12, style: :bold
      pdf.text "#{@worksheet.stuck_point_belief_before}%", size: 11
      pdf.move_down 10
    end

    # C. Emotions Before
    if @worksheet.emotions_before.present? && @worksheet.emotions_before.any?
      add_emotions_section(pdf, 'C. Emotions Before', @worksheet.emotions_before)
    end

    # D. Exploring Thoughts (7 questions)
    if @worksheet.exploring_complete?
      pdf.text 'D. Use the Challenging Questions to examine your stuck point', size: 12, style: :bold
      pdf.move_down 5

      AlternativeThought::EXPLORING_QUESTIONS.each do |field, question|
        answer = @worksheet.send(field)
        next if answer.blank?

        pdf.text question, size: 11, style: :bold
        pdf.text answer, size: 10
        pdf.move_down 8
      end
      pdf.move_down 10
    end

    # E. Thinking Patterns
    if @worksheet.patterns_complete?
      pdf.text 'E. Patterns of Problematic Thinking', size: 12, style: :bold
      pdf.move_down 5

      AlternativeThought::THINKING_PATTERNS.each do |field, pattern|
        answer = @worksheet.send(field)
        next if answer.blank?

        pdf.text pattern, size: 11, style: :bold
        pdf.text answer, size: 10
        pdf.move_down 8
      end
      pdf.move_down 10
    end

    # F. Alternative Thought
    if @worksheet.alternative_thought.present?
      pdf.text 'F. Alternative Thought', size: 12, style: :bold
      pdf.text @worksheet.alternative_thought, size: 10
      pdf.move_down 5

      if @worksheet.alternative_thought_belief.present?
        pdf.text "How much do you believe the alternative thought? #{@worksheet.alternative_thought_belief}%",
                 size: 10, style: :italic
      end
      pdf.move_down 10
    end

    # G. Re-rate Stuck Point
    if @worksheet.stuck_point_belief_after.present?
      pdf.text 'G. Re-rate Stuck Point', size: 12, style: :bold
      pdf.text "How much do you believe the stuck point now? #{@worksheet.stuck_point_belief_after}%", size: 10
      pdf.move_down 10
    end

    # H. Emotions After
    if @worksheet.emotions_after.present? && @worksheet.emotions_after.any?
      add_emotions_section(pdf, 'H. Emotions After', @worksheet.emotions_after)
    end
  end

  # Helper: Adds a simple text section with label and content
  def add_section(pdf, label, content)
    return if content.blank?

    pdf.text label, size: 12, style: :bold
    pdf.text content, size: 10
    pdf.move_down 10
  end

  # Helper: Adds an emotions table from JSONB array [{emotion:, intensity:}]
  def add_emotions_section(pdf, label, emotions_array)
    pdf.text label, size: 12, style: :bold
    pdf.move_down 5

    # Build table data
    table_data = [['Emotion', 'Intensity (0-10)']]
    emotions_array.each do |entry|
      emotion = entry['emotion']&.capitalize || 'Unknown'
      intensity = entry['intensity'] || 0
      table_data << [emotion, intensity.to_s]
    end

    # Render table
    pdf.table(table_data, header: true, width: 300) do
      row(0).font_style = :bold
      row(0).background_color = 'DDDDDD'
      cells.padding = 8
      cells.borders = [:top, :bottom, :left, :right]
    end

    pdf.move_down 10
  end
end
