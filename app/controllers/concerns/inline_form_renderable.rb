# Shared controller helpers for inline Turbo Frame editing patterns.
# Used by controllers that support in-place title editing (IndexEvents, StuckPoints).
module InlineFormRenderable
  extend ActiveSupport::Concern

  included do
    include ActionView::RecordIdentifier
  end

  private

  # Renders the shared inline form partial within a Turbo Frame.
  # The frame_id must match the turbo_frame_tag wrapping the editable element.
  # rubocop:disable Metrics/ParameterLists
  def render_inline_form(model, url:, placeholder:, frame_id:, attribute_name:,
                         cancel_url: nil, hidden_fields: {}, status: :ok)
    render 'shared/inline_form',
           locals: { model: model, url: url, placeholder: placeholder,
                     frame_id: frame_id, attribute_name: attribute_name,
                     cancel_url: cancel_url, hidden_fields: hidden_fields },
           layout: false,
           status: status
  end
  # rubocop:enable Metrics/ParameterLists

  # Dual-format response: Turbo Stream for AJAX, redirect for non-JS fallback.
  # The HTML fallback ensures the app works with JavaScript disabled.
  def respond_with_turbo_or_redirect(&block)
    respond_to do |format|
      format.turbo_stream(&block)
      format.html { redirect_to root_path }
    end
  end

  # Removes a record's DOM element via Turbo Stream after deletion.
  def turbo_stream_remove(record)
    respond_with_turbo_or_redirect do
      render turbo_stream: turbo_stream.remove(dom_id(record))
    end
  end
end
