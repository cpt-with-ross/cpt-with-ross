# frozen_string_literal: true

# =============================================================================
# InlineFormRenderable - Turbo Frame In-Place Editing Support
# =============================================================================
#
# This concern provides reusable patterns for inline editing with Turbo Frames.
# It's used for the "click to edit" UX where clicking a title or text field
# replaces it with an input form, and submitting swaps back to the display view.
#
# Pattern Implementation:
# 1. Display view wraps content in a turbo_frame_tag with a specific ID
# 2. Edit link/button targets that frame and fetches the edit action
# 3. render_inline_form renders an input within the same frame ID
# 4. Form submission returns a Turbo Stream that replaces the frame content
#
# This concern also provides progressive enhancement helpers:
# - respond_with_turbo_or_redirect: Turbo Stream for JS, redirect for no-JS
# - turbo_stream_remove: Standard pattern for deleting with Turbo Stream
#
module InlineFormRenderable
  extend ActiveSupport::Concern

  included do
    include ActionView::RecordIdentifier
  end

  private

  # Renders the shared inline form partial within a Turbo Frame.
  #
  # Parameters:
  # - model: The ActiveRecord model being edited
  # - url: Form submission URL
  # - placeholder: Input placeholder text
  # - frame_id: Must match the turbo_frame_tag ID in the display view
  # - attribute_name: The model attribute being edited (e.g., :title, :statement)
  # - cancel_url: Optional URL for cancel button (returns to display view)
  # - hidden_fields: Hash of additional hidden field values
  # - status: HTTP status code (useful for re-rendering with :unprocessable_entity)
  #
  # rubocop:disable Metrics/ParameterLists
  def render_inline_form(model, url:, placeholder:, frame_id:, attribute_name:,
                         cancel_url: nil, hidden_fields: {}, status: :ok)
    render partial: 'shared/inline_form',
           locals: { model: model, url: url, placeholder: placeholder,
                     frame_id: frame_id, attribute_name: attribute_name,
                     cancel_url: cancel_url, hidden_fields: hidden_fields },
           status: status
  end
  # rubocop:enable Metrics/ParameterLists

  # Dual-format response helper for progressive enhancement.
  # Turbo Stream for JavaScript-enabled browsers, redirect for no-JS fallback.
  def respond_with_turbo_or_redirect(&block)
    respond_to do |format|
      format.turbo_stream(&block)
      format.html { redirect_to root_path }
    end
  end

  # Standard Turbo Stream deletion pattern - removes the record's DOM element.
  # Uses dom_id helper to generate consistent element IDs (e.g., "stuck_point_123").
  def turbo_stream_remove(record)
    respond_with_turbo_or_redirect do
      render turbo_stream: turbo_stream.remove(dom_id(record))
    end
  end
end
