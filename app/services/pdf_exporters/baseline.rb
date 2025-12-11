# frozen_string_literal: true

module PdfExporters
  # Generates a professional PDF for the Baseline (Impact Statement) assessment
  # matching the official CPT worksheet layout with 3 sections:
  # - Page 1: Event Identification
  # - Page 2: PCL-5 Checklist
  # - Page 3: Impact Statement
  class Baseline < Base
    IMPACT_QUESTIONS = [
      'Who have you been thinking is to blame for this event?',
      'Have you been thinking of things you should have done differently? If so, what?',
      'Have you been thinking of things other people should have done differently? If so, what?',
      'Have you been thinking the event could have been prevented? If so, how?',
      'Why do you think this event happened to you (versus to someone else)?',
      'What does it mean about you that this event happened?',
      'If the event happened to someone else, why do you think it happened to them (versus to another person)?'
    ].freeze

    def initialize(baseline)
      super()
      @baseline = baseline
      @index_event = baseline.index_event
    end

    protected

    def add_content(pdf)
      add_event_identification_page(pdf)
      pdf.start_new_page
      add_pcl_checklist_page(pdf)
      pdf.start_new_page
      add_impact_statement_page(pdf)
    end

    private

    # Page 1: Event Identification
    def add_event_identification_page(pdf)
      add_banner_header(pdf, 'Baseline PTSD Checklist')

      add_instructions(pdf)
      add_event_details(pdf)
      add_experience_type_section(pdf)
      add_death_cause_section(pdf)
    end

    def add_instructions(pdf)
      pdf.text 'Instructions:', size: 11, style: :bold
      pdf.move_down 3
      pdf.text 'This questionnaire asks about problems you may have had after a very stressful experience ' \
               'involving actual or threatened death, serious injury, or sexual violence.',
               size: 10, color: COLORS[:text_dark]
      pdf.move_down 10
    end

    def add_event_details(pdf)
      add_labeled_field(pdf, label: 'Index Event', value: @index_event.title)
      add_labeled_field(pdf, label: 'How long ago did it happen?', value: @baseline.time_since_event)

      # Death/injury/violence question
      pdf.text 'Did it involve actual or threatened death, serious injury, or sexual violence?',
               size: 10, style: :bold, color: COLORS[:text_dark]
      pdf.move_down 5
      add_checkbox_item(pdf, 'Yes', checked: @baseline.involved_death_injury_violence == true)
      add_checkbox_item(pdf, 'No', checked: @baseline.involved_death_injury_violence == false)
      pdf.move_down 5
    end

    def add_experience_type_section(pdf)
      pdf.text 'How did you experience it?', size: 10, style: :bold, color: COLORS[:text_dark]
      pdf.move_down 5

      ::Baseline::EXPERIENCE_TYPES.each do |key, label|
        is_selected = @baseline.experience_type == key
        add_checkbox_item(pdf, label, checked: is_selected)
      end

      if @baseline.experience_type == 'other' && @baseline.experience_other_description.present?
        pdf.indent(20) do
          pdf.text @baseline.experience_other_description, size: 10, color: COLORS[:text_dark]
        end
      end
      pdf.move_down 5
    end

    def add_death_cause_section(pdf)
      pdf.text 'If the event involved the death of a close family member or close friend, was it due to ' \
               'some kind of accident or violence, or was it due to natural causes?',
               size: 10, style: :bold, color: COLORS[:text_dark]
      pdf.move_down 5

      ::Baseline::DEATH_CAUSE_TYPES.each do |key, label|
        is_selected = @baseline.death_cause_type == key
        add_checkbox_item(pdf, label, checked: is_selected)
      end
    end

    # Page 2: PCL-5 Checklist
    def add_pcl_checklist_page(pdf)
      add_banner_header(pdf, 'PCL-5 Checklist')

      pdf.text 'In the past month, how much were you bothered by:', size: 10, style: :bold
      pdf.move_down 5

      add_pcl_table(pdf)
      add_pcl_total(pdf)
    end

    def add_pcl_table(pdf)
      headers = ['', 'Not at all', 'A little bit', 'Moderately', 'Quite a bit', 'Extremely']

      rows = ::Baseline::PCL_QUESTIONS.map.with_index do |(attr, question), idx|
        value = @baseline.send(attr)
        row = ["#{idx + 1}. #{question}"]

        # Add rating columns (0-4)
        5.times do |rating|
          row << (value == rating ? 'X' : '')
        end

        row
      end

      # Calculate column widths - use 35% for questions to give more room to rating headers
      question_width = pdf.bounds.width * 0.35
      rating_width = (pdf.bounds.width - question_width) / 5.0

      add_alternating_table(
        pdf,
        headers: headers,
        rows: rows,
        column_widths: [question_width] + ([rating_width] * 5)
      )
    end

    def add_pcl_total(pdf)
      pdf.move_down 10
      pdf.text "Total Score: #{@baseline.pcl_total_score} / 80",
               size: 12, style: :bold, color: COLORS[:text_dark], align: :right
    end

    # Page 3: Impact Statement
    def add_impact_statement_page(pdf)
      add_banner_header(pdf, 'Impact Statement')

      add_impact_instructions(pdf)
      add_impact_content(pdf)
    end

    def add_impact_instructions(pdf)
      pdf.text 'Please write about why you think your worst traumatic event occurred and the effects ' \
               'it has had on your beliefs about yourself, others, and the world.',
               size: 10, color: COLORS[:text_dark]
      pdf.move_down 10

      pdf.text 'Here are some questions that might be helpful to consider:', size: 10, style: :bold
      pdf.move_down 5

      IMPACT_QUESTIONS.each do |question|
        pdf.text "- #{question}", size: 9, color: COLORS[:text_light]
        pdf.move_down 3
      end

      pdf.move_down 5
      pdf.text 'Consider the effects on: safety, trust, power/control, esteem, and intimacy.',
               size: 10, style: :italic, color: COLORS[:text_light]
      pdf.move_down 10
    end

    def add_impact_content(pdf)
      # Draw a light box for the statement content - use remaining space minus room for timestamp
      pdf.fill_color COLORS[:row_alt]
      statement_height = pdf.cursor - 30
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, statement_height
      pdf.fill_color COLORS[:text_dark]

      pdf.bounding_box([10, pdf.cursor - 10], width: pdf.bounds.width - 20, height: statement_height - 20) do
        if @baseline.statement.present?
          pdf.text @baseline.statement, size: 10, color: COLORS[:text_dark]
        else
          pdf.text 'Impact statement not yet written.', size: 10, color: COLORS[:text_light], style: :italic
        end
      end

      pdf.move_cursor_to 20
    end
  end
end
