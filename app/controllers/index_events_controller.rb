# frozen_string_literal: true

# =============================================================================
# IndexEventsController - Managing Traumatic Event Records
# =============================================================================
#
# An "Index Event" in CPT is the traumatic event being processed in therapy.
# It's the root of the CPT hierarchy: IndexEvent -> StuckPoints -> Worksheets.
#
# This controller handles CRUD operations with Turbo Stream responses for the
# SPA-like experience. Key patterns:
#
# - Inline editing: Title edits happen in-place via Turbo Frames
# - Multi-stream responses: Updates may affect both sidebar and main content
# - Deletion fallback: When deleting, check if user was viewing child content
#
# All actions use Turbo Streams with HTML fallback for progressive enhancement.
#
class IndexEventsController < ApplicationController
  include InlineFormRenderable
  include IndexEventContentHelper

  before_action :set_index_event, only: %i[show edit update destroy]

  # Returns the title button partial - used for Turbo Frame refresh after cancel
  def show
    render partial: 'index_events/title_button',
           locals: { index_event: @index_event, is_active: false },
           layout: false
  end

  # Renders inline form for creating a new IndexEvent in the sidebar
  def new
    @index_event = current_user.index_events.build
    render_inline_form @index_event,
                       url: index_events_path,
                       placeholder: 'Name your new Index Event (Optional)...',
                       frame_id: 'new_index_event_form_frame',
                       attribute_name: :title
  end

  # Renders inline form for editing an existing IndexEvent title
  def edit
    render_inline_form @index_event,
                       url: index_event_path(@index_event),
                       placeholder: 'Name your new Index Event (Optional)...',
                       frame_id: dom_id(@index_event, :title_frame),
                       attribute_name: :title,
                       cancel_url: index_event_path(@index_event)
  end

  # Creates a new IndexEvent and its associated Baseline (auto-created via callback).
  # On success: adds to sidebar, clears form, shows baseline in main content.
  def create
    @index_event = current_user.index_events.build(index_event_params)

    if @index_event.save
      respond_with_turbo_or_redirect do
        render turbo_stream: [
          # Add new item to sidebar accordion (expanded so drawer is open)
          turbo_stream.append('indexEventsAccordion',
                              partial: 'index_events/sidebar_item',
                              locals: { index_event: @index_event, is_active: true, expanded: true }),
          # Clear the inline form
          turbo_stream.update('new_index_event_form_frame', ''),
          # Show the new event's baseline in main content
          turbo_stream.update('main_content',
                              partial: 'baselines/show_content',
                              locals: { baseline: @index_event.baseline,
                                        index_event: @index_event })
        ]
      end
    else
      render_inline_form @index_event,
                         url: index_events_path,
                         placeholder: 'Name your new Index Event (Optional)...',
                         frame_id: 'new_index_event_form_frame',
                         attribute_name: :title,
                         status: :unprocessable_content
    end
  end

  # Updates the IndexEvent title. If user is viewing related content (baseline,
  # worksheets, etc.), refresh that content to reflect the new title.
  def update
    if @index_event.update(index_event_params)
      respond_with_turbo_or_redirect do
        viewing_baseline = params[:current_path] == index_event_baseline_path(@index_event)

        streams = [
          turbo_stream.replace(
            dom_id(@index_event, :title_frame),
            partial: 'index_events/title_button',
            locals: { index_event: @index_event, is_active: viewing_baseline }
          )
        ]

        # If viewing a child resource, refresh it so headers show updated title
        child_content = find_viewed_child_content
        streams << turbo_stream.update('main_content', child_content) if child_content

        render turbo_stream: streams
      end
    else
      render_inline_form @index_event,
                         url: index_event_path(@index_event),
                         placeholder: 'Name your new Index Event (Optional)...',
                         frame_id: dom_id(@index_event, :title_frame),
                         attribute_name: :title,
                         cancel_url: index_event_path(@index_event),
                         status: :unprocessable_content
    end
  end

  # Deletes the IndexEvent and all children (cascade delete via dependent: :destroy).
  # If user was viewing any child content, shows welcome screen instead.
  def destroy
    related_paths = build_related_paths(@index_event)
    @index_event.destroy

    respond_to do |format|
      format.turbo_stream do
        streams = [turbo_stream.remove(dom_id(@index_event))]
        # If user was viewing deleted content, show welcome screen
        if viewing_related_content?(related_paths)
          streams << turbo_stream.update('main_content', partial: 'dashboard/welcome')
        end
        render turbo_stream: streams
      end
      format.html { redirect_to root_path }
    end
  end

  private

  # Finds IndexEvent scoped to current user for authorization
  def set_index_event
    @index_event = current_user.index_events.find(params[:id])
  end

  def index_event_params
    params.require(:index_event).permit(:title)
  end
end
