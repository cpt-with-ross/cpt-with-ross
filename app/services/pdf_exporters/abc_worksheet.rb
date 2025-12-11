# frozen_string_literal: true

module PdfExporters
  # Generates a professional PDF for ABC Worksheets
  # matching the official CPT worksheet layout with:
  # - Gray banner header
  # - 3-column table (A, B, C)
  # - Context info for Index Event and Stuck Point
  class AbcWorksheet < Base
    def initialize(abc_worksheet)
      super()
      @worksheet = abc_worksheet
      @stuck_point = abc_worksheet.stuck_point
      @index_event = @stuck_point.index_event
    end

    protected

    def add_content(pdf)
      add_banner_header(pdf, 'ABC Worksheet')
      add_worksheet_context(pdf, index_event: @index_event, stuck_point: @stuck_point)
      add_professional_abc_table(pdf, @worksheet)
    end
  end
end
