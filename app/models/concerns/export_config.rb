# frozen_string_literal: true

# =============================================================================
# ExportConfig - Centralized configuration for PDF export, print, and share
# =============================================================================
#
# Single source of truth for all exportable resources. Used by:
# - Exportable concern (controllers)
# - ExportMailer
# - ApplicationHelper (path generation)
#
# To add a new exportable resource:
# 1. Add an entry to RESOURCES hash below
# 2. Include Exportable in the controller
# 3. Call `exportable :resource_key` in the controller
#
module ExportConfig
  TIMESTAMP_FORMAT = '%Y%m%d-%H%M%S'

  RESOURCES = {
    abc_worksheet: {
      model: 'AbcWorksheet',
      exporter: 'PdfExporters::AbcWorksheet',
      filename_prefix: 'abc-worksheet',
      subject_prefix: 'ABC Worksheet',
      title_method: :title
    },
    alternative_thought: {
      model: 'AlternativeThought',
      exporter: 'PdfExporters::AlternativeThought',
      filename_prefix: 'alternative-thought',
      subject_prefix: 'Alternative Thought',
      title_method: :title
    },
    stuck_point: {
      model: 'StuckPoint',
      exporter: 'PdfExporters::StuckPoint',
      filename_prefix: 'stuck-point',
      subject_prefix: 'Stuck Point',
      title_method: ->(r) { r.statement.truncate(50) }
    },
    baseline: {
      model: 'Baseline',
      exporter: 'PdfExporters::Baseline',
      filename_prefix: 'impact-statement',
      subject_prefix: 'Impact Statement',
      title_method: :title
    }
  }.freeze

  class << self
    def config_for(key)
      RESOURCES[key.to_sym] || raise(ArgumentError, "Unknown export type: #{key}")
    end

    def key_for_model(model_class)
      model_name = model_class.is_a?(Class) ? model_class.name : model_class.class.name
      key, = RESOURCES.find { |_, config| config[:model] == model_name }
      key || raise(ArgumentError, "No export config for model: #{model_name}")
    end

    def exporter_for(key)
      config_for(key)[:exporter].constantize
    end

    def title_for(resource, key = nil)
      key ||= key_for_model(resource)
      config = config_for(key)
      title_method = config[:title_method]

      if title_method.is_a?(Proc)
        title_method.call(resource)
      else
        resource.public_send(title_method)
      end
    end

    def filename_for(resource, key = nil)
      key ||= key_for_model(resource)
      config = config_for(key)
      title = title_for(resource, key)
      slug = title.parameterize.truncate(50, omission: '')
      timestamp = Time.current.strftime(TIMESTAMP_FORMAT)

      "#{config[:filename_prefix]}-#{slug}-#{timestamp}.pdf"
    end

    def subject_for(resource, key = nil)
      key ||= key_for_model(resource)
      config = config_for(key)
      title = title_for(resource, key)

      "CPT #{config[:subject_prefix]}: #{title}"
    end
  end
end
