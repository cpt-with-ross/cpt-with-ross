# frozen_string_literal: true

module PdfExporters
  # Generates a professional PDF for Stuck Point overview
  # Contains full content for all nested ABC Worksheets and Alternative Thoughts
  class StuckPoint < Base
    def initialize(stuck_point)
      super()
      @stuck_point = stuck_point
      @index_event = stuck_point.index_event
      @abc_worksheets = stuck_point.abc_worksheets.order(created_at: :asc)
      @alternative_thoughts = stuck_point.alternative_thoughts.order(created_at: :asc)
    end

    protected

    def add_content(pdf)
      add_banner_header(pdf, 'Stuck Point Overview')
      add_section_card(pdf, title: 'Index Event', content: @index_event.title)
      add_section_card(pdf, title: 'Stuck Point', content: @stuck_point.statement)
      add_abc_worksheets_section(pdf)
      add_alternative_thoughts_section(pdf)
    end

    private

    def add_abc_worksheets_section(pdf)
      if @abc_worksheets.any?
        @abc_worksheets.each_with_index do |worksheet, _idx|
          ensure_space_for_section(pdf)
          add_abc_worksheet_with_table(pdf, worksheet)
        end
      else
        add_section_card(pdf, title: 'ABC Worksheets', content: 'No ABC worksheets have been created yet.')
      end
    end

    def add_abc_worksheet_with_table(pdf, worksheet)
      add_section_card_header(pdf, "ABC Worksheet: #{worksheet.title}", dark: true)
      add_professional_abc_table(pdf, worksheet)
    end

    def add_alternative_thoughts_section(pdf)
      ensure_space_for_section(pdf)

      if @alternative_thoughts.any?
        @alternative_thoughts.each_with_index do |thought, idx|
          ensure_space_for_section(pdf) if idx.positive?
          add_full_alternative_thought(pdf, thought, idx + 1)
        end
      else
        add_section_card(pdf, title: 'Alternative Thoughts', content: 'No alternative thoughts have been created yet.')
      end
    end

    def add_full_alternative_thought(pdf, thought, _number)
      add_section_card_header(pdf, "Alternative Thought: #{thought.title}", dark: true)

      # Initial belief & Emotions Before
      add_belief_and_emotions_before(pdf, thought)

      # Exploring Thoughts
      add_exploring_thoughts_cards(pdf, thought)

      # Thinking Patterns
      add_thinking_patterns_cards(pdf, thought)

      # Alternative Thought
      add_alternative_thought_result(pdf, thought)

      # Re-rate & Emotions After
      add_rerate_and_emotions_after(pdf, thought)
    end

    def add_belief_and_emotions_before(pdf, thought)
      parts = []
      if thought.stuck_point_belief_before.present?
        parts << "<b>Initial belief rating:</b> #{thought.stuck_point_belief_before}%"
      end
      emotions_before = format_emotions_text(thought.emotions_before)
      parts << "<b>Emotions Before:</b> #{emotions_before}" if emotions_before
      return if parts.empty?

      add_section_card(pdf, title: 'Starting Point', content: parts.join("\n\n"), inline_format: true)
    end

    def add_exploring_thoughts_cards(pdf, thought)
      answered = ::AlternativeThought::EXPLORING_QUESTIONS.select do |field, _|
        thought.send(field).present?
      end
      return if answered.empty?

      answered.each_with_index do |(field, question), idx|
        title = idx.zero? ? "Exploring Thoughts: #{question}" : question
        add_section_card(pdf, title: title, content: thought.send(field))
      end
    end

    def add_thinking_patterns_cards(pdf, thought)
      answered = ::AlternativeThought::THINKING_PATTERNS.select do |field, _|
        thought.send(field).present?
      end
      return if answered.empty?

      answered.each_with_index do |(field, pattern), idx|
        title = idx.zero? ? "Thinking Patterns: #{pattern}" : pattern
        add_section_card(pdf, title: title, content: thought.send(field))
      end
    end

    def add_alternative_thought_result(pdf, thought)
      return if thought.alternative_thought.blank?

      parts = ["<b>Alternative Thought:</b> #{thought.alternative_thought}"]
      if thought.alternative_thought_belief.present?
        parts << "<b>Belief rating:</b> #{thought.alternative_thought_belief}%"
      end

      add_section_card(pdf, title: 'New Perspective', content: parts.join("\n\n"), inline_format: true)
    end

    def add_rerate_and_emotions_after(pdf, thought)
      parts = []
      if thought.stuck_point_belief_after.present?
        parts << "<b>Current belief rating:</b> #{thought.stuck_point_belief_after}%"
      end
      emotions_after = format_emotions_text(thought.emotions_after)
      parts << "<b>Emotions After:</b> #{emotions_after}" if emotions_after
      return if parts.empty?

      add_section_card(pdf, title: 'Outcome', content: parts.join("\n\n"), inline_format: true)
    end

    def format_emotions_text(emotions)
      return nil unless emotions.present? && emotions.any? { |e| e['intensity'].to_i.positive? }

      emotions
        .select { |e| e['intensity'].to_i.positive? }
        .sort_by { |e| -e['intensity'].to_i }
        .map { |e| "#{e['emotion'].capitalize}: #{e['intensity']}/10" }
        .join(', ')
    end
  end
end
