# frozen_string_literal: true

module PdfExporters
  # Generates a professional PDF for Alternative Thought worksheets
  # matching the official CPT worksheet layout with sections A-H:
  # A. Situation, B. Stuck Point, C. Emotions Before, D. Exploring Thoughts,
  # E. Thinking Patterns, F. Alternative Thought, G. Re-rate, H. Emotions After
  class AlternativeThought < Base
    def initialize(alternative_thought)
      super()
      @worksheet = alternative_thought
      @stuck_point = alternative_thought.stuck_point
      @index_event = @stuck_point.index_event
      @baseline = @index_event.baseline
    end

    protected

    def add_content(pdf)
      add_banner_header(pdf, 'Alternative Thoughts Worksheet')
      add_section_card(pdf, title: 'Index Event', content: @index_event.title)

      add_section_a_situation(pdf)
      add_section_b_stuck_point(pdf)
      add_section_c_emotions_before(pdf)
      add_section_d_exploring_thoughts(pdf)
      add_section_e_thinking_patterns(pdf)
      add_section_f_alternative_thought(pdf)
      add_section_g_rerate(pdf)
      add_section_h_emotions_after(pdf)
    end

    private

    def add_section_a_situation(pdf)
      add_section_card(pdf, title: 'Situation',
                            content: @baseline&.statement.presence || 'No impact statement written.')
    end

    def add_section_b_stuck_point(pdf)
      belief = @worksheet.stuck_point_belief_before
      belief_text = belief.present? ? "#{belief}%" : 'Not rated'
      content = "#{@stuck_point.statement}\n\nInitial belief rating: #{belief_text}"
      add_section_card(pdf, title: 'Stuck Point', content: content)
    end

    def add_section_c_emotions_before(pdf)
      add_section_card(pdf, title: 'Emotions Before', content: format_emotions_list(@worksheet.emotions_before))
    end

    def add_section_d_exploring_thoughts(pdf)
      ::AlternativeThought::EXPLORING_QUESTIONS.each_with_index do |(field, question), idx|
        answer = @worksheet.send(field)
        title = idx.zero? ? "Exploring Thoughts: #{question}" : question
        add_section_card(pdf, title: title, content: answer.presence || 'Not answered')
      end
    end

    def add_section_e_thinking_patterns(pdf)
      ::AlternativeThought::THINKING_PATTERNS.each_with_index do |(field, pattern), idx|
        answer = @worksheet.send(field)
        title = idx.zero? ? "Thinking Patterns: #{pattern}" : pattern
        add_section_card(pdf, title: title, content: answer.presence || 'Not answered')
      end
    end

    def add_section_f_alternative_thought(pdf)
      belief = @worksheet.alternative_thought_belief
      belief_text = belief.present? ? "#{belief}%" : 'Not rated'
      thought = @worksheet.alternative_thought.presence || 'Not yet written.'
      content = "#{thought}\n\nBelief rating: #{belief_text}"
      add_section_card(pdf, title: 'Alternative Thought(s)', content: content)
    end

    def add_section_g_rerate(pdf)
      belief = @worksheet.stuck_point_belief_after
      content = "Current belief rating: #{belief.present? ? "#{belief}%" : 'Not rated'}"
      add_section_card(pdf, title: 'Re-rate Old Stuck Point', content: content)
    end

    def add_section_h_emotions_after(pdf)
      add_section_card(pdf, title: 'Emotions After', content: format_emotions_list(@worksheet.emotions_after))
    end

    def format_emotions_list(emotions)
      if emotions.present? && emotions.any? { |e| e['intensity'].to_i.positive? }
        emotions
          .select { |e| e['intensity'].to_i.positive? }
          .sort_by { |e| -e['intensity'].to_i }
          .map { |e| "#{e['emotion'].capitalize}: #{e['intensity']}/10" }
          .join("\n")
      else
        'No emotions recorded.'
      end
    end
  end
end
